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
    class ViewModel: ObservableObject {
        private enum Err: Error {
            case unknown, noData, timeout, noMandatoryCharacteristic
        }
        
        let peripheral: Peripheral
        let runningService: CBService
        
        let environment = Environment()
        
        // MARK: Mandatory Characteristics
        var rscMeasurement: CBCharacteristic!
        var rscFeature: CBCharacteristic!
        
        // MARK: Optional Characteristics
        var sensorLocation: CBCharacteristic?
        var scControlPoint: CBCharacteristic?
        
        private var cancelable = Set<AnyCancellable>()
        
        init(peripheral: Peripheral, runningService: CBService) {
            assert(runningService.uuid.uuidString == Service.runningSpeedAndCadence.uuidString, "bad service")
            self.peripheral = peripheral
            self.runningService = runningService
        }
    }
}

extension RunningServiceScreen.ViewModel {
    private func discoverCharacteristics() async throws {
        let serviceCharacteristics: [Characteristic] = [.rscMeasurement, .rscFeature, .sensorLocation, .scControlPoint]
        let discoveredCharacteristics: [CBCharacteristic]
        
        discoveredCharacteristics = try await peripheral.discoverCharacteristics(serviceCharacteristics.map(\.uuid), for: runningService).value
        
        for ch in discoveredCharacteristics {
            switch ch.uuid {
            case .rscMeasurement:
                self.rscMeasurement = ch
            case .rscFeature:
                self.rscFeature = ch
            case .sensorLocation:
                self.sensorLocation = ch
            case .scControlPoint:
                self.scControlPoint = ch
            default:
                break
            }
        }
        
        guard rscMeasurement != nil && rscFeature != nil else {
            throw Err.noMandatoryCharacteristic
        }
        
        environment.rscFeature = try await peripheral.readValue(for: rscFeature).tryMap { data in
            guard let data = data else { throw Err.noData }
            return RSCFeature(rawValue: data[0])
        }
        .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: { Err.timeout })
        .value
    }
    
    private func enableMeasurementNotifications() async throws {
        _ = try await peripheral.setNotifyValue(true, for: rscMeasurement).value
        
        peripheral.listenValues(for: rscMeasurement)
            .map { RunningSpeedAndCadence.RSCSMeasurement(from: $0) }
            .sink { _ in
                
            } receiveValue: { [unowned self] measurement in
                self.environment.instantaneousSpeed = Measurement(value: Double(measurement.instantaneousSpeed) / 256.0, unit: .metersPerSecond)
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
    }
}

// MARK: - Environment
extension RunningServiceScreen.ViewModel {
    class Environment: ObservableObject {
        @Published fileprivate (set) var error: ReadableError?
        @Published fileprivate (set) var rscFeature: RSCFeature = .none
        
        @Published var instantaneousSpeed: Measurement<UnitSpeed>?
        @Published var instantaneousCadence: Int?
        @Published var instantaneousStrideLength: Measurement<UnitLength>?
        @Published var totalDistance: Measurement<UnitLength>?
        @Published var isRunning: Bool?
    }
}

extension RunningServiceScreen.ViewModel.Environment {
    enum CriticalError: Error {
        case noMandatoryCharacteristics
    }
    
    enum AlertError: Error { }
}

extension RunningServiceScreen.ViewModel.Environment.CriticalError {
    var readableError: ReadableError {
        switch self {
        case .noMandatoryCharacteristics:
            ReadableError(title: "Error", message: "Can't discover mandatory characteristics")
        }
    }
}

extension RunningServiceScreen.ViewModel.Environment.AlertError {
    
}
