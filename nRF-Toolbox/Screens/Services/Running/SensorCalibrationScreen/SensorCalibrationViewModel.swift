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
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - SensorCalibrationViewModel

@MainActor
final class SensorCalibrationViewModel: ObservableObject {
    
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
    
    private let peripheral: Peripheral
    private let rscService: CBService
    private let features: BitField<RSCSFeature>
    private var scControlPoint: CBCharacteristic!
    private var sensorLocationCharacteristic: CBCharacteristic?
    
    private let log = NordicLog(category: "SensorCalibration.VM")
    
    // MARK: init
    
    init(peripheral: Peripheral, rscService: CBService, features: BitField<RSCSFeature>) {
        self.peripheral = peripheral
        self.rscService = rscService
        self.features = features
        
        setCumulativeValueEnabled = features.contains(.totalDistanceMeasurement)
        startSensorCalibrationEnabled = features.contains(.sensorCalibrationProcedure)
        
        Publishers.CombineLatest($pickerSensorLocation, $currentSensorLocation)
            .map { $0 == $1 }
            .assign(to: &$updateSensorLocationDisabled)
        
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
                criticalError = .noMandatoryCharacteristic
                log.debug("Error: \(criticalError.nilDescription)")
                return
            }
            self.scControlPoint = scControlPoint
            guard try await peripheral.setNotifyValue(true, for: self.scControlPoint).firstValue else {
                criticalError = .cantEnableNotifyCharacteristic
                log.debug("Error: \(criticalError.nilDescription)")
                return
            }
            
            sensorLocationCharacteristic = discovered.first(where: { $0.uuid == Characteristic.sensorLocation.uuid })
        } catch let error {
            log.error("Error: \(error.localizedDescription)")
            criticalError = .noMandatoryCharacteristic
            return
        }
    }
    
    func readLocations() async {
        log.debug(#function)
        guard features.contains(.multipleSensorLocation) else { return }
        
        do {
            availableSensorLocations = try await readAvailableLocations()
            let sensorLocation = try await readSensorLocation()
            currentSensorLocation = sensorLocation.rawValue
            pickerSensorLocation = sensorLocation.rawValue
            
            guard !availableSensorLocations.isEmpty else {
                internalError = .unableReadSensorLocation
                log.debug("Error: \(internalError.nilDescription)")
                return
            }
        } catch let error {
            log.error("Error: \(error.localizedDescription)")
            internalError = .unableReadSensorLocation
            return
        }
        
        sensorLocationEnabled = true
    }
}

extension SensorCalibrationViewModel {
    
    func resetCumulativeValue() async {
        var meters: UInt32 = 0
        let data = Data(bytes: &meters, count: MemoryLayout.size(ofValue: meters))
        
        do {
            try await writeCommand(opCode: .setCumulativeValue, parameter: data)
        } catch let error {
            log.error(error.localizedDescription)
            internalError = .unableResetCumulativeValue
        }
    }
    
    func startSensorCalibration() async {
        do {
            try await writeCommand(opCode: .startSensorCalibration, parameter: nil)
        } catch {
            log.debug("Error: \(internalError.nilDescription)")
            internalError = .unableStartCalibration
        }
    }
    
    func updateSensorLocation() async {
        do {
            let data = Data([pickerSensorLocation])
            try await writeCommand(opCode: .updateSensorLocation, parameter: data)
            currentSensorLocation = pickerSensorLocation
        } catch {
            log.debug("Error: \(internalError.nilDescription)")
            internalError = .unableWriteSensorLocation
            updateSensorLocationDisabled = false
        }
    }
    
    @discardableResult
    private func writeCommand(opCode: RunningSpeedAndCadence.OpCode, parameter: Data?) async throws -> Data? {
        log.debug(#function)
        guard let scControlPoint else {
            throw Err.noMandatoryCharacteristic
        }
        
        var data = opCode.data
        
        if let parameter {
            data.append(parameter)
        }
        
        let valuePublisher = self.peripheral.listenValues(for: scControlPoint)
            .compactMap {
                RunningSpeedAndCadence.SCControlPointResponse(from: $0)
            }
            .first(where: {
                $0.opCode == opCode // Listen to response with the same OpCode
            })
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
        log.debug(#function)
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
        log.debug(#function)
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

// MARK: - Error Types
extension SensorCalibrationViewModel {
    
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
