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
import Combine

// MARK: - RunningServiceViewModel

final class RunningServiceViewModel: @MainActor SupportedServiceViewModel, ObservableObject {
    private enum Err: Error {
        case unknown, noData, timeout, noMandatoryCharacteristic
    }
    
    let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    
    lazy private(set) var environment = Environment()
    
    // MARK: Mandatory Characteristics
    var rscMeasurement: CBCharacteristic!
    var rscFeature: CBCharacteristic!
    var scControlPoint: CBCharacteristic?
    
    private var cancelable = Set<AnyCancellable>()
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    private let log = NordicLog(category: "RunningService.ViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.characteristics = characteristics
        log.debug(#function)
    }
    
    deinit {
        log.debug(#function)
    }
    
    // MARK: description
    
    var description: String {
        "Running"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return RunningServiceView()
            .environmentObject(self.environment)
    }
    
    // MARK: onConnect()
    
    func onConnect() async {
        log.debug(#function)
        await enableDeviceCommunication()
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        cancelable.removeAll()
    }
}

extension RunningServiceViewModel {
    
    // MARK: enableDeviceCommunication()
    
    public func enableDeviceCommunication() async {
        log.debug(#function)
        do {
            try await initializeCharacteristics()
            try await readFeature()
        } catch let error as Err {
            switch error {
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

private extension RunningServiceViewModel {
    
    // MARK: initializeCharacteristics()
    
    func initializeCharacteristics() async throws {
        log.debug(#function)
        let serviceCharacteristics: [Characteristic] = [.rscMeasurement, .rscFeature, .scControlPoint]
        let discoveredCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
            characteristics.contains { $0.uuid == cbChar.uuid }
        }
        
        for characteristic in discoveredCharacteristics {
            switch characteristic.uuid {
            case .rscMeasurement:
                self.rscMeasurement = characteristic
            case .rscFeature:
                self.rscFeature = characteristic
            case .scControlPoint:
                self.scControlPoint = characteristic
            default:
                break
            }
        }
        
        self.environment.isSensorCalibrationAvailable = scControlPoint != nil
        
        guard rscMeasurement != nil && rscFeature != nil else {
            throw Err.noMandatoryCharacteristic
        }
    }
    
    // MARK: readFeature()
    @MainActor
    func readFeature() async throws {
        log.debug(#function)
        let features = try await peripheral.readValue(for: rscFeature)
            .tryMap { data in
                guard let data else { throw Err.noData }
                return BitField<RSCSFeature>(RegisterValue(data[0]))
            }
            .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: { Err.timeout })
            .firstValue
        
        let calibrationViewModel = SensorCalibrationViewModel(peripheral: peripheral, characteristics: characteristics, features: features)
        environment.sensorCalibrationViewModel = calibrationViewModel
        await calibrationViewModel.initializeCharacteristic()
        await calibrationViewModel.readLocations()
        environment.features = features
    }
    
    // MARK: enableMeasurementNotifications()
    
    func enableMeasurementNotifications() async throws {
        peripheral.listenValues(for: rscMeasurement)                    // Listen for values
            .map {
                RSCSMeasurement(from: $0) // Map Data into readable struct
            }
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    self.log.debug("Finished!")
                case .failure(let error):
                    self.log.error("error: \(error.localizedDescription)")
                }
                
            } receiveValue: { [unowned self] measurement in
                self.environment.instantaneousSpeed = measurement.instantaneousSpeed
                self.environment.instantaneousCadence = Int(measurement.instantaneousCadence)
                
                if measurement.flags.contains(.instantaneousStrideLengthMeasurement) {
                    self.environment.instantaneousStrideLength = measurement.instantaneousStrideLength
                }
                
                if measurement.flags.contains(.totalDistanceMeasurement) {
                    self.environment.totalDistance = measurement.totalDistance
                }
                
                self.environment.isRunning = measurement.flags.contains(.walkingOrRunningStatus)
            }
            .store(in: &cancelable)
        
        _ = try await peripheral.setNotifyValue(true, for: rscMeasurement).firstValue
    }
}

// MARK: - Environment

extension RunningServiceViewModel {
    
    class Environment: ObservableObject {
        @Published fileprivate(set) var criticalError: CriticalError?
        @Published fileprivate(set) var alertError: AlertError?
        
        @Published fileprivate(set) var features = BitField<RSCSFeature>()
        
        @Published var instantaneousSpeed: Measurement<UnitSpeed>?
        @Published var instantaneousCadence: Int?
        @Published var instantaneousStrideLength: Measurement<UnitLength>?
        @Published var totalDistance: Measurement<UnitLength>?
        @Published var isRunning: Bool?
        @Published var isSensorCalibrationAvailable: Bool?
        
        @Published var sensorCalibrationViewModel: SensorCalibrationViewModel?
        
        private let log = NordicLog(category: "RunningService.ViewModel.Environment")
        
        init(criticalError: CriticalError? = nil, alertError: AlertError? = nil,
             features: BitField<RSCSFeature> = [],
             instantaneousSpeed: Measurement<UnitSpeed>? = nil,
             instantaneousCadence: Int? = nil,
             instantaneousStrideLength: Measurement<UnitLength>? = nil,
             totalDistance: Measurement<UnitLength>? = nil,
             isRunning: Bool? = nil) {
            self.criticalError = criticalError
            self.alertError = alertError
            self.features = features
            self.instantaneousSpeed = instantaneousSpeed
            self.instantaneousCadence = instantaneousCadence
            self.instantaneousStrideLength = instantaneousStrideLength
            self.totalDistance = totalDistance
            self.isRunning = isRunning
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}

// MARK: - Error

extension RunningServiceViewModel.Environment {
    
    enum CriticalError: Error {
        case noMandatoryCharacteristics
        case noData
        case unknown
    }
    
    enum AlertError: Error { }
}

// MARK: - CriticalError

extension RunningServiceViewModel.Environment.CriticalError {
    
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
