//
//  SensorCalibrationViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 21/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine
import SwiftUI
import iOS_BLE_Library_Mock
import CoreBluetoothMock_Collection
import iOS_Bluetooth_Numbers_Database

extension SensorCalibrationScreen {
    @MainActor
    class ViewModel: ObservableObject {
        private (set) lazy var environment = Environment(
            resetCumulativeValue: { [unowned self] in await self.resetCumulativeValue() },
            startSensorCalibration: { [unowned self] in await self.startSensorCalibration() }
        )
        
        let peripheral: Peripheral
        let rscFeature: RSCFeature
        
        private let rscService: CBService
        private var scControlPoint: CBCharacteristic!
        private var sensorLocationCharacteristic: CBCharacteristic?
        
        init(peripheral: Peripheral, rscService: CBService, rscFeature: RSCFeature) {
            self.peripheral = peripheral
            self.rscService = rscService
            self.rscFeature = rscFeature
            
            environment.setCumulativeValueEnabled = rscFeature.contains(.totalDistanceMeasurement)
            environment.startSensorCalibrationEnabled = rscFeature.contains(.sensorCalibrationProcedure)
        }
    }
}

extension SensorCalibrationScreen.ViewModel {
    func discoverCharacteristic() async {
        do {
            let characteristics: [Characteristic] = [.scControlPoint, .sensorLocation]
            let discovered = try await peripheral.discoverCharacteristics(characteristics.map(\.uuid), for: rscService).value
            
            guard let scControlPoint = discovered.first(where: { $0.uuid == Characteristic.scControlPoint.uuid }) else {
                environment.criticalError = .noMandatoryCharacteristic
                return
            }
            
            self.sensorLocationCharacteristic = discovered.first(where: { $0.uuid == Characteristic.sensorLocation.uuid })
        } catch {
            environment.criticalError = .noMandatoryCharacteristic
            return
        }
    }
    
    func readLocations() async {
        guard rscFeature.contains(.multipleSensorLocation) else {
            return
        }
        
        do {
            environment.availableSensorLocations = try await readAvailableLocations()
            environment.currentSensorLocation = try await readSensorLocation()
            
            guard !environment.availableSensorLocations.isEmpty else {
                environment.alertError = .unableReadSensorLocation
                return
            }
        } catch {
            environment.alertError = .unableReadSensorLocation
            return
        }
        
        environment.sensorLocationEnabled = true 
    }

}

extension SensorCalibrationScreen.ViewModel {
    private func resetCumulativeValue() async {
        var meters: UInt32 = 0
        let data = Data(bytes: &meters, count: MemoryLayout.size(ofValue: meters))
        
        do {
            try await writeCommand(opCode: .setCumulativeValue, parameter: data)
        } catch {
            environment.alertError = .unableResetCumulativeValue
        }
    }
    
    private func startSensorCalibration() async {
        do {
            try await writeCommand(opCode: .startSensorCalibration, parameter: nil)
        } catch {
            environment.alertError = .unableStartCalibration
        }
    }
    
    @discardableResult
    private func writeCommand(opCode: RunningSpeedAndCadence.OpCode, parameter: Data?) async throws -> Data? {
        guard let scControlPoint else {
            throw Err.noMandatoryCharacteristic
        }
        
        var data = opCode.data
        
        if let parameter {
            data.append(parameter)
        }
        
        let valuePublisher = self.peripheral.listenValues(for: scControlPoint)
            .compactMap { RunningSpeedAndCadence.SCControlPointResponse(from: $0) }
            .first(where: { $0.opCode == opCode })
            .tryMap { response -> Data? in
                guard response.responseValue == .success else {
                    throw Err.controlPointError(response.responseValue)
                }
                return response.parameter
            }
        
        return try await peripheral.writeValueWithResponse(data, for: scControlPoint)
            .combineLatest(valuePublisher)
            .map { $0.1 }
            .value
    }
    
    func readSensorLocation() async throws -> SensorLocation {
        guard let sensorLocationCharacteristic else {
            throw Err.noMandatoryCharacteristic
        }
        
        guard let value = try await peripheral.readValue(for: sensorLocationCharacteristic).value else {
            throw Err.badData
        }
        
        guard let location = SensorLocation(rawValue: value[0]) else {
            throw Err.badData
        }
        
        return location
    }
    
    func readAvailableLocations() async throws -> [SensorLocation] {
        guard let data = try await writeCommand(opCode: .requestSupportedSensorLocations, parameter: nil) else {
            throw Err.badData
        }
        
        return data.compactMap { SensorLocation(rawValue: $0) }
    }
}

private extension SensorCalibrationScreen.ViewModel {
    enum Err: Error {
        case controlPointError(RunningSpeedAndCadence.ResponseCode)
        case noMandatoryCharacteristic
        case badData
    }
}

extension SensorCalibrationScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        // MARK: Features
        @Published fileprivate (set) var setCumulativeValueEnabled = false
        @Published fileprivate (set) var startSensorCalibrationEnabled = false
        @Published fileprivate (set) var sensorLocationEnabled = false
                
        @Published var updateSensorLocationDisabled = false
        @Published fileprivate (set) var currentSensorLocation: SensorLocation = .other
        @Published fileprivate (set) var availableSensorLocations: [SensorLocation] = []
        
        @Published fileprivate (set) var alertError: AlertError? = nil
        @Published fileprivate (set) var criticalError: CriticalError? = nil
        
        let resetCumulativeValue: () async -> ()
        let startSensorCalibration: () async -> ()
        let updateSensorLocation: (SensorLocation) async -> ()
        
        init(
            setCumulativeValueEnabled: Bool = false,
            startSensorCalibrationEnabled: Bool = false,
            sensorLocationEnabled: Bool = false,
            updateSensorLocationDisabled: Bool = false,
            currentSensorLocation: SensorLocation = .other,
            availableSensorLocations: [SensorLocation] = [],
            alertError: AlertError? = nil,
            criticalError: CriticalError? = nil,
            resetCumulativeValue: @escaping () async -> () = { },
            startSensorCalibration: @escaping () async -> () = { },
            updateSensorLocation: @escaping (SensorLocation) async -> () = { _ in }
        ) {
            self.setCumulativeValueEnabled = setCumulativeValueEnabled
            self.startSensorCalibrationEnabled = startSensorCalibrationEnabled
            self.sensorLocationEnabled = sensorLocationEnabled
            self.updateSensorLocationDisabled = updateSensorLocationDisabled
            self.currentSensorLocation = currentSensorLocation
            self.availableSensorLocations = availableSensorLocations
            self.alertError = alertError
            self.criticalError = criticalError
            self.resetCumulativeValue = resetCumulativeValue
            self.startSensorCalibration = startSensorCalibration
            self.updateSensorLocation = updateSensorLocation
        }
        
    }
}

extension SensorCalibrationScreen.ViewModel.Environment {
    enum CriticalError: Error {
        case noMandatoryCharacteristic
    }
    
    enum AlertError: Error {
        case unableResetCumulativeValue
        case unableStartCalibration
        case unableReadSensorLocation
    }
}
