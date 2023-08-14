//
//  RunningServiceHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import iOS_BLE_Library
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
    
    enum Error: Swift.Error {
        case timeout, noMandatoryCharacteristic, noData, badData, parseError, controlPointError(RunningSpeedAndCadence.ResponseCode)
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
    
    @Published var instantaneousSpeed: SomeValue = SomeValue(systemName: "hare.fill", text: "Instantaneous Speed", value: "--", isActive: false, color: .green)
    @Published var instantaneousCadence: SomeValue = SomeValue(systemName: "shoeprints.fill", text: "Instantaneous Cadence", value: "--", isActive: false, color: .blue)
    @Published var instantaneousStrideLength: SomeValue = SomeValue(systemName: "ruler.fill", text: "Instantaneous Stride Length", value: "--", isActive: false, color: .purple)
    @Published var totalDistance: SomeValue = SomeValue(systemName: "map.fill", text: "Total Distance", value: "--", isActive: false, color: .cyan)
    
    // MARK: Sensor Location
    @Published var sensorLocationValue: SensorLocation?
    @Published var sensorLocationSupported: Bool = false
    @Published var readingSersorLocation: Bool = false 
    
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
        let characteristicsSeq = peripheral.discoverCharacteristics([.rscFeature, .rscMeasurement], for: service)
            .autoconnect()
            .timeout(.seconds(3), scheduler: DispatchQueue.main, customError: { Error.timeout })
        
        for try await ch in characteristicsSeq.values {
            switch ch.uuid {
            case .rscMeasurement:
                rscMeasurement = ch
            case .rscFeature:
                rscFeature = ch
            default:
                break
            }
        }
        
        guard rscMeasurement != nil && rscFeature != nil else {
            throw Error.noMandatoryCharacteristic
        }
        
        self.features = try await readSupportedFeatures()
       
        if features.contains(.multipleSensorLocation) {
            self.sensorLocationCh = try await peripheral.discoverCharacteristics([.sensorLocation], for: service)
                .autoconnect()
                .value
            
            self.sensorLocationSupported = true
        }
        
        if features.contains(.sensorCalibrationProcedure) {
            self.scControlPointCh = try await peripheral.discoverCharacteristics([.scControlPoint], for: service)
                .autoconnect()
                .value
            
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

extension RunningServiceHandler {
    public func presentError(_ error: Swift.Error) {
        self.error = ReadableError(error: error)
        self.showError = true
    }
    
    func updateValues(distance: Measurement<UnitLength>?, sensorLocation: SensorLocation?) async {
        do {
            if let distance {
                try await writeCumulativeValue(newDistance: distance)
            }
            if let sensorLocation {
                try await writeSensorLocation(newLocation: sensorLocation)
            }
        } catch let e {
            self.presentError(e)
        }
    }
}

// MARK: - Sensor Settings
extension RunningServiceHandler {
    // MARK: Read Values
    func readSensorLocation() async throws -> SensorLocation {
        guard let sensorLocationCh else {
            throw Error.noMandatoryCharacteristic
        }
        
        guard let value = try await peripheral.readValue(for: sensorLocationCh).value else {
            throw Error.noData
        }
        
        guard let location = SensorLocation(rawValue: value[0]) else {
            throw Error.badData
        }
        
        return location
    }
    
    func readSupportedFeatures() async throws -> RSCFeature {
        guard let feauturesData = try await peripheral.readValue(for: rscFeature).value else {
            throw Error.noData
        }
        
        return RunningSpeedAndCadence.RSCFeature(rawValue: feauturesData[0])
    }
    
    func readAvailableLocations() async throws -> [SensorLocation] {
        guard let data = try await writeCommand(opCode: .requestSupportedSensorLocations, parameter: nil) else {
            throw Error.noData
        }
        
        return data.compactMap { SensorLocation(rawValue: $0) }
    }
    
    // MARK: Write Values
    @discardableResult
    func writeCommand(opCode: RunningSpeedAndCadence.OpCode, parameter: Data?) async throws -> Data? {
        guard let scControlPointCh else {
            throw Error.noMandatoryCharacteristic
        }
        
        var data = opCode.data
        
        if let parameter {
            data.append(parameter)
        }
        
        let valuePublisher = self.peripheral.listenValues(for: scControlPointCh)
            .compactMap { RunningSpeedAndCadence.SCControlPointResponse(from: $0) }
            .first(where: { response in response.opCode == opCode })
            .map { response -> Data? in
                response.parameter
            }
        
        let writePublisher = peripheral.writeValueWithResponse(data, for: scControlPointCh).autoconnect()
        
        return try await writePublisher.combineLatest(valuePublisher)
            .map { $0.1 }
            .value
    }
    
    func writeCumulativeValue(newDistance: Measurement<UnitLength>) async throws {
        var meters = Int(newDistance.converted(to: .meters).value)
        let data = Data(bytes: &meters, count: MemoryLayout.size(ofValue: meters))
        
        try await writeCommand(opCode: .setCumulativeValue, parameter: data)
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
