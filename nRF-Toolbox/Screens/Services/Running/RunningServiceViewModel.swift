//
//  RunningServiceViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection
import Combine

private extension CBUUID {
    static let rscMeasurement = CBUUID(characteristic: .rscMeasurement)
    static let rscFeature = CBUUID(characteristic: .rscFeature)
    static let sensorLocation = CBUUID(characteristic: .sensorLocation)
    static let scControlPoint = CBUUID(characteristic: .scControlPoint)
}

extension RunningServiceScreen {
    @MainActor
    class RunningServiceViewModel: ObservableObject {
        private enum Err: Error {
            case unknown, noData, timeout, noMandatoryCharacteristic
        }
        
        let peripheral: Peripheral
        let runningService: CBService
        
        lazy private (set) var environment = Environment(
            sensorCalibrationViewModel: { [unowned self] in self.sensorCalibrationViewModel }
        )
        
        // MARK: Mandatory Characteristics
        var rscMeasurement: CBCharacteristic!
        var rscFeature: CBCharacteristic!
        
        private var cancelable = Set<AnyCancellable>()
        
        private var sensorCalibrationViewModel: SensorCalibrationScreen.SensorCalibrationViewModel?
        
        private let l = L(category: "RunningService.ViewModel")
        
        init(peripheral: Peripheral, runningService: CBService) {
            assert(runningService.uuid.uuidString == Service.runningSpeedAndCadence.uuidString, "bad service")
            self.peripheral = peripheral
            self.runningService = runningService
            
            l.construct()
        }
        
        deinit {
            l.descruct()
        }
    }
}

extension RunningServiceScreen.RunningServiceViewModel: SupportedServiceViewModel {
    func onConnect() {
        Task {
            await enableDeviceCommunication()
        }
    }
    
    func onDisconnect() {
        cancelable.removeAll()
    }
}

extension RunningServiceScreen.RunningServiceViewModel {
    public func enableDeviceCommunication() async {
        do {
            try await discoverCharacteristics()
            try await readFeature()
        } catch let e as Err {
            switch e {
            case .timeout, .noMandatoryCharacteristic:
                environment.criticalError = Environment.CriticalError.noMandatoryCharacteristics
            case .noData:
                environment.criticalError = Environment.CriticalError.noData
            case .unknown:
                environment.criticalError = Environment.CriticalError.unknown
            }
            return
        } catch {
            environment.criticalError = Environment.CriticalError.unknown
            return
        }
        
        do {
            try await enableMeasurementNotifications()
        } catch {
            environment.criticalError = Environment.CriticalError.unknown
        }
    }
}

extension RunningServiceScreen.RunningServiceViewModel {
    private func discoverCharacteristics() async throws {
        let serviceCharacteristics: [Characteristic] = [.rscMeasurement, .rscFeature]
        let discoveredCharacteristics: [CBCharacteristic]
        
        discoveredCharacteristics = try await peripheral.discoverCharacteristics(serviceCharacteristics.map(\.uuid), for: runningService).value
        
        for ch in discoveredCharacteristics {
            switch ch.uuid {
            case .rscMeasurement:
                self.rscMeasurement = ch
            case .rscFeature:
                self.rscFeature = ch
            default:
                break
            }
        }
        
        guard rscMeasurement != nil && rscFeature != nil else {
            throw Err.noMandatoryCharacteristic
        }
    }
    
    private func readFeature() async throws {
        let rscFeature = try await peripheral.readValue(for: rscFeature).tryMap { data in
            guard let data = data else { throw Err.noData }
            return RSCFeature(rawValue: data[0])
        }
        .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: { Err.timeout })
        .value
        
        sensorCalibrationViewModel = SensorCalibrationScreen.SensorCalibrationViewModel(peripheral: peripheral, rscService: runningService, rscFeature: rscFeature )
        environment.rscFeature = rscFeature
    }
    
    private func enableMeasurementNotifications() async throws {
        peripheral.listenValues(for: rscMeasurement)
            .map { RunningSpeedAndCadence.RSCSMeasurement(from: $0) }
            .sink { completion in
                switch completion {
                case .finished:
                    print("finished")
                case .failure(let e):
                    print("error: \(e.localizedDescription)")
                }
                
            } receiveValue: { [unowned self] measurement in
                self.environment.instantaneousSpeed = Measurement(value: Double(measurement.instantaneousSpeed) / 256.0, unit: UnitSpeed.metersPerSecond)
                self.environment.instantaneousCadence = Int(measurement.instantaneousCadence)
                
                if measurement.flags.contains(.instantaneousStrideLengthPresent) {
                    self.environment.instantaneousStrideLength = Measurement(value: Double(measurement.instantaneousStrideLength!), unit: .centimeters)
                }
                
                if measurement.flags.contains(.totalDistancePresent) {
                    self.environment.totalDistance = Measurement(value: Double(measurement.totalDistance!), unit: .meters)
                }
                
                self.environment.isRunning = measurement.flags.contains(.walkingOrRunningStatus)
            }
            .store(in: &cancelable)
        
        _ = try await peripheral.setNotifyValue(true, for: rscMeasurement).value
    }
}

// MARK: - Environment
extension RunningServiceScreen.RunningServiceViewModel {
    class Environment: ObservableObject {
        @Published fileprivate (set) var criticalError: CriticalError?
        @Published fileprivate (set) var alertError: AlertError?
        
        @Published fileprivate (set) var rscFeature: RSCFeature = .none
        
        @Published var instantaneousSpeed: Measurement<UnitSpeed>?
        @Published var instantaneousCadence: Int?
        @Published var instantaneousStrideLength: Measurement<UnitLength>?
        @Published var totalDistance: Measurement<UnitLength>?
        @Published var isRunning: Bool?
        
        let sensorCalibrationViewModel: (() -> (SensorCalibrationScreen.SensorCalibrationViewModel?))
        
        private let l = L(category: "RunningService.ViewModel.Environment")
        
        init(
            criticalError: CriticalError? = nil,
            alertError: AlertError? = nil,
            rscFeature: RSCFeature = .none,
            instantaneousSpeed: Measurement<UnitSpeed>? = nil,
            instantaneousCadence: Int? = nil,
            instantaneousStrideLength: Measurement<UnitLength>? = nil,
            totalDistance: Measurement<UnitLength>? = nil,
            isRunning: Bool? = nil,
            sensorCalibrationViewModel: @escaping (() -> (SensorCalibrationScreen.SensorCalibrationViewModel?)) = { nil }
        ) {
            self.criticalError = criticalError
            self.alertError = alertError
            self.rscFeature = rscFeature
            self.instantaneousSpeed = instantaneousSpeed
            self.instantaneousCadence = instantaneousCadence
            self.instantaneousStrideLength = instantaneousStrideLength
            self.totalDistance = totalDistance
            self.isRunning = isRunning
            self.sensorCalibrationViewModel = sensorCalibrationViewModel
            
            l.construct()
        }
        
        deinit {
            l.descruct()
        }
    }
}

extension RunningServiceScreen.RunningServiceViewModel.Environment {
    enum CriticalError: Error {
        case noMandatoryCharacteristics
        case noData
        case unknown
    }
    
    enum AlertError: Error { }
}

extension RunningServiceScreen.RunningServiceViewModel.Environment.CriticalError {
    var readableError: ReadableError {
        switch self {
        case .noMandatoryCharacteristics:
            ReadableError(title: "Error", message: "Can't discover mandatory characteristics")
        case .noData:
            ReadableError(title: "Error", message: "Can't read required data")
        case .unknown:
            ReadableError(title: "Error", message: "Unknown error has occurred")
        }
    }
}

extension RunningServiceScreen.RunningServiceViewModel.Environment.AlertError {
    
}
