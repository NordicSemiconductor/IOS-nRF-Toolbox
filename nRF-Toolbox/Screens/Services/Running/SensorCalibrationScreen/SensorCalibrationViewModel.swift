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
import iOS_Common_Libraries

// MARK: - SensorCalibrationViewModel

@MainActor
final class SensorCalibrationViewModel: ObservableObject {
    private(set) lazy var environment = Environment(
        resetCumulativeValue: { [unowned self] in await self.resetCumulativeValue() },
        startSensorCalibration: { [unowned self] in await self.startSensorCalibration() },
        updateSensorLocation: { [unowned self] in await self.updateSensorLocation() }
    )
    
    let peripheral: Peripheral
    let rscFeature: RSCFeature
    
    private let rscService: CBService
    private var scControlPoint: CBCharacteristic!
    private var sensorLocationCharacteristic: CBCharacteristic?
    
    private let log = NordicLog(category: "SensorCalibration.VM")
    private var cancelable = Set<AnyCancellable>()
    
    init(peripheral: Peripheral, rscService: CBService, rscFeature: RSCFeature) {
        self.peripheral = peripheral
        self.rscService = rscService
        self.rscFeature = rscFeature
        
        environment.setCumulativeValueEnabled = rscFeature.contains(.totalDistanceMeasurement)
        environment.startSensorCalibrationEnabled = rscFeature.contains(.sensorCalibrationProcedure)
        
        log.debug(#function)
    }
    
    deinit {
        log.debug(#function)
    }
}

extension SensorCalibrationViewModel {
    
    func discoverCharacteristic() async {
        log.debug(#function)
        do {
            let characteristics: [Characteristic] = [.scControlPoint, .sensorLocation]
            let discovered = try await peripheral.discoverCharacteristics(characteristics.map(\.uuid), for: rscService).firstValue
            
            guard let scControlPoint = discovered.first(where: { $0.uuid == Characteristic.scControlPoint.uuid }) else {
                environment.criticalError = .noMandatoryCharacteristic
                return
            }
            self.scControlPoint = scControlPoint
            guard try await peripheral.setNotifyValue(true, for: self.scControlPoint).firstValue else {
                environment.criticalError = .cantEnableNotifyCharacteristic
                return 
            }
            
            self.sensorLocationCharacteristic = discovered.first(where: { $0.uuid == Characteristic.sensorLocation.uuid })
        } catch let error {
            log.error("Error: \(error.localizedDescription)")
            environment.criticalError = .noMandatoryCharacteristic
            return
        }
    }
    
    func readLocations() async {
        log.debug(#function)
        guard rscFeature.contains(.multipleSensorLocation) else { return }
        
        do {
            environment.availableSensorLocations = try await readAvailableLocations()
            let sensorLocation = try await readSensorLocation()
            environment.currentSensorLocation = sensorLocation.rawValue
            environment.pickerSensorLocation = sensorLocation.rawValue
            
            guard !environment.availableSensorLocations.isEmpty else {
                environment.internalError = .unableReadSensorLocation
                return
            }
        } catch let error {
            log.error("Error: \(error.localizedDescription)")
            environment.internalError = .unableReadSensorLocation
            return
        }
        
        environment.sensorLocationEnabled = true 
    }
}

extension SensorCalibrationViewModel {
    
    private func resetCumulativeValue() async {
        var meters: UInt32 = 0
        let data = Data(bytes: &meters, count: MemoryLayout.size(ofValue: meters))
        
        do {
            try await writeCommand(opCode: .setCumulativeValue, parameter: data)
        } catch let error {
            log.error(error.localizedDescription)
            environment.internalError = .unableResetCumulativeValue
        }
    }
    
    private func startSensorCalibration() async {
        do {
            try await writeCommand(opCode: .startSensorCalibration, parameter: nil)
        } catch {
            environment.internalError = .unableStartCalibration
        }
    }
    
    private func updateSensorLocation() async {
        do {
            let data = Data([environment.pickerSensorLocation])
            try await writeCommand(opCode: .updateSensorLocation, parameter: data)
            environment.currentSensorLocation = environment.pickerSensorLocation
        } catch {
            environment.internalError = .unableWriteSensorLocation
            environment.updateSensorLocationDisabled = false 
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
            .first(where: { $0.opCode == opCode }) // Listen to response with the same OpCode
            .tryMap { response -> Data? in
                guard response.responseValue == .success else {
                    throw Err.controlPointError(response.responseValue)
                }
                return response.parameter
            }
        
        return try await peripheral.writeValueWithResponse(data, for: scControlPoint)
            .combineLatest(valuePublisher)
            .map { $0.1 }
            .firstValue
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

// MARK: - Internal Error

private extension SensorCalibrationViewModel {
    enum Err: Error {
        case controlPointError(RunningSpeedAndCadence.ResponseCode)
        case noMandatoryCharacteristic
        case badData
    }
}

// MARK: - Environment

extension SensorCalibrationViewModel {
    
    @MainActor
    class Environment: ObservableObject {
        
        // MARK: Features
        
        @Published fileprivate(set) var setCumulativeValueEnabled = false
        @Published fileprivate(set) var startSensorCalibrationEnabled = false
        @Published fileprivate(set) var sensorLocationEnabled = false
                
        @Published var updateSensorLocationDisabled = false
        @Published fileprivate(set) var currentSensorLocation: SensorLocation.RawValue = 0
        @Published var pickerSensorLocation: SensorLocation.RawValue = 0
        
        @Published fileprivate(set) var availableSensorLocations: [SensorLocation] = []
        
        fileprivate var internalError: AlertError? = nil {
            didSet {
                self.alertError = internalError
            }
        }
        @Published var alertError: Error? = nil
        @Published fileprivate(set) var criticalError: CriticalError? = nil
        
        let resetCumulativeValue: () async -> ()
        let startSensorCalibration: () async -> ()
        let updateSensorLocation: () async -> ()
        
        private let log = NordicLog(category: "SensorCalibrationViewModel.Environment")
        
        init(setCumulativeValueEnabled: Bool = false,
             startSensorCalibrationEnabled: Bool = false,
             sensorLocationEnabled: Bool = false,
             updateSensorLocationDisabled: Bool = false,
             currentSensorLocation: SensorLocation.RawValue = 0,
             pickerSensorLocation: SensorLocation.RawValue = 0,
             availableSensorLocations: [SensorLocation] = [],
             
             alertError: AlertError? = nil,
             criticalError: CriticalError? = nil,
             
             resetCumulativeValue: @escaping () async -> () = { },
             startSensorCalibration: @escaping () async -> () = { },
             updateSensorLocation: @escaping () async -> () = { }) {
            self.setCumulativeValueEnabled = setCumulativeValueEnabled
            self.startSensorCalibrationEnabled = startSensorCalibrationEnabled
            self.sensorLocationEnabled = sensorLocationEnabled
            self.updateSensorLocationDisabled = updateSensorLocationDisabled
            self.currentSensorLocation = currentSensorLocation
            self.pickerSensorLocation = pickerSensorLocation
            self.availableSensorLocations = availableSensorLocations
            self.alertError = alertError
            self.criticalError = criticalError
            self.resetCumulativeValue = resetCumulativeValue
            self.startSensorCalibration = startSensorCalibration
            self.updateSensorLocation = updateSensorLocation
            
            Publishers.CombineLatest($pickerSensorLocation, $currentSensorLocation)
                .map { $0 == $1 }
                .assign(to: &$updateSensorLocationDisabled)
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}

// MARK: - Error Types
extension SensorCalibrationViewModel.Environment {
    
    enum CriticalError: LocalizedError {
        case noMandatoryCharacteristic
        case cantEnableNotifyCharacteristic
    }
    
    enum AlertError: LocalizedError {
        case unableResetCumulativeValue
        case unableStartCalibration
        case unableReadSensorLocation
        case unableWriteSensorLocation
        
        var errorDescription: String? {
            switch self {
            case .unableResetCumulativeValue:
                return "Unable to reset cumulative value"
            case .unableStartCalibration:
                return "Unable to start calibration"
            case .unableReadSensorLocation:
                return "Unable to read sensor location"
            case .unableWriteSensorLocation:
                return "Unable to write sensor location"
            }
        }
    }
}
