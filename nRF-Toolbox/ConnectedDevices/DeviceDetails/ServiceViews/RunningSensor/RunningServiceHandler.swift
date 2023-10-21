//
//  RunningServiceHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import Foundation
import Combine
import SwiftUI

private extension CBMUUID {
    static let rscMeasurement = CBMUUID(characteristic: .rscMeasurement)
    static let rscFeature = CBMUUID(characteristic: .rscFeature)
    static let sensorLocation = CBMUUID(characteristic: .sensorLocation)
    static let scControlPoint = CBMUUID(characteristic: .scControlPoint)
}

@MainActor
class RunningServiceHandler: ServiceHandler, ObservableObject {
    
    private var cancelables = Set<AnyCancellable>()
    
    enum Err: LocalizedError {
        case timeout, noMandatoryCharacteristic(CBMCharacteristic?), noData, badData, controlPointError(RunningSpeedAndCadence.ResponseCode)
        
        var errorDescription: String? {
            switch self {
            case .timeout:
                return "Operation timed out"
            case .noMandatoryCharacteristic(let ch):
                if let ch, let characteristic = Characteristic.find(by: ch.uuid) {
                    return "No \(characteristic.name) characteristic"
                } else {
                    return "No mandatory characteristic"
                }
            case .badData:
                return "Can't parse data"
            case .noData:
                return "Empty data"
            case .controlPointError(let code):
                return "Control point error: \(code.description)"
            }
        }
    }
    
    // MARK: Characteristics
    var rscMeasurement: CBCharacteristic!
    var rscFeature: CBCharacteristic!
    var features: RunningSpeedAndCadence.RSCFeature!
    
    @Published var sensorLocationCh: CBCharacteristic?
    @Published var scControlPointCh: CBCharacteristic?
    
    @Published var measurement: RSCMeasurement?
    @Published var error: ReadableError?
    @Published var showError: Bool = false
    
    @Published var instantaneousSpeed: LabledValue = LabledValue(systemName: "hare.fill", text: "Instantaneous Speed", value: "--", isActive: false, color: .green)
    @Published var instantaneousCadence: LabledValue = LabledValue(systemName: "shoeprints.fill", text: "Instantaneous Cadence", value: "--", isActive: false, color: .blue)
    @Published var instantaneousStrideLength: LabledValue = LabledValue(systemName: "ruler.fill", text: "Instantaneous Stride Length", value: "--", isActive: false, color: .purple)
    @Published var totalDistance: LabledValue = LabledValue(systemName: "map.fill", text: "Total Distance", value: "--", isActive: false, color: .cyan)
    
    // MARK: Sensor Location
    @Published var sensorLocationValue: SensorLocation?
    @Published var sensorLocationSupported: Bool = false
    @Published var readingSersorLocation: Bool = false
    
    @Published var runningOrWalking: Bool? = nil
    
    override init?(peripheral: Peripheral, service: CBService) {
        guard service.uuid.uuidString == Service.runningSpeedAndCadence.uuidString else {
            return nil
        }

        super.init(peripheral: peripheral, service: service)
        
        Task {
            do {
                try await prepare()
                enableMeasurement()
            } catch let e {
                print(e.localizedDescription)
            }
        }
    }
    
    override var image: Image {
        Image(systemName: "figure.run")
    }
    
    func prepare() async throws {
        let characteristicsSeq = try await peripheral.discoverCharacteristics([.rscFeature, .rscMeasurement], for: service)
            .timeout(.seconds(3), scheduler: DispatchQueue.main, customError: { Err.timeout })
            .value
        
        for ch in characteristicsSeq {
            switch ch.uuid {
            case .rscMeasurement:
                rscMeasurement = ch
            case .rscFeature:
                rscFeature = ch
            default:
                break
            }
        }
        
        guard rscMeasurement != nil else {
            throw Err.noMandatoryCharacteristic(rscMeasurement)
        }
        
        guard rscFeature != nil else {
            throw Err.noMandatoryCharacteristic(rscFeature)
        }
        
        self.features = try await readSupportedFeatures()
       
        if features.contains(.multipleSensorLocation) {
            self.sensorLocationCh = try await peripheral.discoverCharacteristics([.sensorLocation], for: service).value.first
            
            self.sensorLocationSupported = true
        }
        
        if features.contains(.sensorCalibrationProcedure) {
            self.scControlPointCh = try await peripheral.discoverCharacteristics([.scControlPoint], for: service).value.first
            
            self.peripheral.peripheral.setNotifyValue(true, for: scControlPointCh!)
        }
    }
    
    func enableMeasurement() {
        peripheral.peripheral.setNotifyValue(true, for: rscMeasurement)
        
        
        peripheral.listenValues(for: rscMeasurement)
            .map { RSCMeasurement(rawData: RunningSpeedAndCadence.RSCSMeasurement(from: $0)) }
            .mapError { error in
                ReadableError(error: error)
            }
            .sink { [unowned self] completion in
                if case .failure(let e) = completion {
                    self.error = e
                }
            } receiveValue: { [unowned self] value in
                self.measurement = value
                
                let nf = NumberFormatter()
                nf.numberStyle = .decimal
                nf.maximumFractionDigits = 1
                
                let formatter = MeasurementFormatter()
                formatter.numberFormatter = nf
                formatter.unitOptions = .naturalScale
                
                self.instantaneousSpeed.updateValue(formatter.string(from: value.instantaneousSpeed))
                self.instantaneousCadence.updateValue("\(value.instantaneousCadence) spm")
                
                if let strideLength = value.instantaneousStrideLength {
                    self.instantaneousStrideLength.updateValue(formatter.string(from: strideLength))
                } else {
                    self.instantaneousStrideLength.isActive = false
                }
                
                if let totalDistance = value.totalDistance {
                    self.totalDistance.updateValue(formatter.string(from: totalDistance))
                } else {
                    self.totalDistance.isActive = false
                }
                
                if self.features.contains(.walkingOrRunningStatus) {
                    self.runningOrWalking = true 
                }
            }
            .store(in: &cancelables)
    }
    
    func updateSensorLocation() async throws {
        readingSersorLocation = true
        defer {
            readingSersorLocation = false
        }
        
        self.sensorLocationValue = try await readSensorLocation()
    }
}

// MARK: - Sensor Settings
extension RunningServiceHandler {
    // MARK: Read Values
    func readSensorLocation() async throws -> SensorLocation {
        guard let sensorLocationCh else {
            throw Err.noMandatoryCharacteristic(sensorLocationCh)
        }
        
        guard let value = try await peripheral.readValue(for: sensorLocationCh).value else {
            throw Err.noData
        }
        
        guard let location = SensorLocation(rawValue: value[0]) else {
            throw Err.badData
        }
        
        return location
    }
    
    func readSupportedFeatures() async throws -> RSCFeature {
        guard let feauturesData = try await peripheral.readValue(for: rscFeature).value else {
            throw Err.noData
        }
        
        return RunningSpeedAndCadence.RSCFeature(rawValue: feauturesData[0])
    }
    
    func readAvailableLocations() async throws -> [SensorLocation] {
        guard let data = try await writeCommand(opCode: .requestSupportedSensorLocations, parameter: nil) else {
            throw Err.noData
        }
        
        return data.compactMap { SensorLocation(rawValue: $0) }
    }
    
    // MARK: Write Values
    @discardableResult
    func writeCommand(opCode: RunningSpeedAndCadence.OpCode, parameter: Data?) async throws -> Data? {
        guard let scControlPointCh else {
            throw Err.noMandatoryCharacteristic(scControlPointCh)
        }
        
        var data = opCode.data
        
        if let parameter {
            data.append(parameter)
        }
        
        let valuePublisher = self.peripheral.listenValues(for: scControlPointCh)
            .compactMap { RunningSpeedAndCadence.SCControlPointResponse(from: $0) }
            .first(where: { $0.opCode == opCode })
            .tryMap { response -> Data? in
                guard response.responseValue == .success else {
                    throw Err.controlPointError(response.responseValue)
                }
                return response.parameter
            }
        
        return try await peripheral.writeValueWithResponse(data, for: scControlPointCh)
            .combineLatest(valuePublisher)
            .map { $0.1 }
            .value
    }
    
    func writeCumulativeValue(newDistance: Measurement<UnitLength>) async throws {
        var meters = UInt32(newDistance.converted(to: .decimeters).value)
        let data = Data(bytes: &meters, count: MemoryLayout.size(ofValue: meters))
        
        try await writeCommand(opCode: .setCumulativeValue, parameter: data)
    }
    
    func startCalibration() async throws {
        try await writeCommand(opCode: .startSensorCalibration, parameter: nil)
    }
    
    func writeSensorLocation(newLocation: SensorLocation) async throws {
        let data = Data([newLocation.rawValue])
        try await writeCommand(opCode: .updateSensorLocation, parameter: data)
    }
}

#if DEBUG

class MockRunningServiceHandler: RunningServiceHandler {
    init() {
        super.init(
            peripheral: Peripheral(
                peripheral: CBMPeripheralPreview(RunningSpeedAndCadence().peripheral),
                delegate: ReactivePeripheralDelegate()),
            service: CBMServiceMock.runningSpeedCadence)!
    }
}

#endif
