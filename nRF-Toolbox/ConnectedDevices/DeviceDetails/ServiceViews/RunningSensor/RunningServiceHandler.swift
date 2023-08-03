//
//  RunningServiceHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database
import CoreBluetoothMock_Collection
import Foundation
import Combine
import SwiftUI

@MainActor
class RunningServiceHandler: ServiceHandler, ObservableObject {
    
    private var cancelables = Set<AnyCancellable>()
    
    enum Error: Swift.Error {
        case timeout, noMandatoryCharacteristic, noData, parseError, controlPointError(RunningSpeedAndCadence.ResponseValue)
    }
    
    // MARK: Characteristics
    var rscMeasurement: CBCharacteristic!
    var rscFeature: CBCharacteristic!
    var features: RunningSpeedAndCadence.RSCFeature!
    
    var sensorLocation: CBCharacteristic?
    var scControlPoint: CBCharacteristic?
    
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
        
        guard let feauturesData = try await peripheral.readValue(for: rscFeature).value else {
            throw Error.noData
        }
        
        self.features = RunningSpeedAndCadence.RSCFeature(rawValue: feauturesData[1])
        
        if features.contains(.multipleSensorLocation) {
            self.sensorLocation = try await peripheral.discoverCharacteristics([.sensorLocation], for: service)
                .autoconnect()
                .value
            
            self.sensorLocationSupported = true
        }
        
        if features.contains(.sensorCalibrationProcedure) {
            self.scControlPoint = try await peripheral.discoverCharacteristics([.scControlPoint], for: service)
                .autoconnect()
                .value
            
            self.peripheral.peripheral.setNotifyValue(true, for: scControlPoint!)
        }
    }
    
    func enableMeasurement() {
        peripheral.peripheral.setNotifyValue(true, for: rscMeasurement)
        
        peripheral.listenValues(for: rscMeasurement)
            .tryMap { try RSCMeasurement(data: $0) }
            .mapError { error in
                ReadableError(error: error)
            }
            .sink { [unowned self] completion in
                if case .failure(let e) = completion {
                    self.error = e
                }
            } receiveValue: { [unowned self] value in
                self.measurement = value
                
                let formatter = MeasurementFormatter()
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
    
    func readSensorLocation() async throws {
        readingSersorLocation = true
        defer {
            readingSersorLocation = false
        }
        guard let sensorLocation else {
            fatalError("there should not be UI that can call this method")
        }
        
        guard let v = try await peripheral.readValue(for: sensorLocation).value else {
            throw Error.noData
        }
        
        self.sensorLocationValue = SensorLocation(rawValue: v[0])
    }
    
    @discardableResult
    func writeCommand(opCode: RunningSpeedAndCadence.OpCode, parameter: Data?) async throws -> Data? {
        guard let scControlPoint else {
            fatalError("control point should not be nil")
        }
        
        var data = Data()
        data.append(opCode.rawValue)
        
        if let parameter {
            data.append(parameter)
        }
        
        let publisher = self.peripheral.listenValues(for: scControlPoint)
            .tryCompactMap { data -> Data? in
                let responseOpCode = RunningSpeedAndCadence.OpCode(rawValue: data[1])!
                guard responseOpCode == opCode else {
                    return nil
                }

                let responseValue = RunningSpeedAndCadence.ResponseValue(rawValue: data[2])!

                if responseValue != .success {
                    throw Error.controlPointError(responseValue)
                }

                if data.count > 3 {
                    return data[3...]
                } else {
                    return nil
                }
            }
            .first()
        
        return try await peripheral.writeValueWithResponse(data, for: scControlPoint)
            .flatMap { _ in publisher }
            .value
    }
    
    func requestSupportedSensorLocations() async throws -> [SensorLocation] {
        guard let data = try await writeCommand(opCode: .requestSupportedSensorLocations, parameter: nil) else {
            throw Error.noData
        }

        let locationsData = [UInt8](data)
        return locationsData.compactMap { SensorLocation(rawValue: $0) }
    }
    
    func setCumulativeValue(newDistance: Measurement<UnitLength>) async throws {
        var meters = Int(newDistance.converted(to: .meters).value)
        let data = Data(bytes: &meters, count: MemoryLayout.size(ofValue: meters))
        
        try await writeCommand(opCode: .setCumulativeValue, parameter: data)
    }
    
    func updateSensorLocation(newLocation: SensorLocation) async throws {
        let data = Data([newLocation.rawValue])
        try await writeCommand(opCode: .updateSensorLocation, parameter: data)
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
                try await setCumulativeValue(newDistance: distance)
            }
            if let sensorLocation {
                try await updateSensorLocation(newLocation: sensorLocation)
            }
        } catch let e {
            self.presentError(e)
        }
    }
}
