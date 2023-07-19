//
//  RunningServiceHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database
import Foundation
import Combine

struct RSCFeature: Flag {
    let value: Int
    
    var instantaneousStrideLengthMeasurement: Bool { enabled(at: 0) }
    var totalDistanceMeasurement: Bool { enabled(at: 1) }
    var walkingOrRunningStatus: Bool { enabled(at: 2) }
    var sensorCalibrationProcedure: Bool { enabled(at: 3) }
    var multipleSensorLocation: Bool { enabled(at: 4) }
}

struct RSCMeasurementFlags: Flag {
    let value: Int

    var instantaneousStrideLengthPresent: Bool { enabled(at: 0) }
    var totalDistancePresent: Bool { enabled(at: 1) }
    var walkingOrRunningStatus: Bool { enabled(at: 2) }
}

struct RSCMeasurement {
    let data: Data 

    let flags: RSCMeasurementFlags
    let instantaneousSpeed: Measurement<UnitSpeed>
    let instantaneousCadence: Int
    let instantaneousStrideLength: Measurement<UnitLength>?
    let totalDistance: Measurement<UnitLength>?

    init(data: Data, flags: RSCMeasurementFlags, instantaneousSpeed: Measurement<UnitSpeed>, instantaneousCadence: Int, instantaneousStrideLength: Measurement<UnitLength>?, totalDistance: Measurement<UnitLength>?) {
        self.data = data
        self.flags = flags
        self.instantaneousSpeed = instantaneousSpeed
        self.instantaneousCadence = instantaneousCadence
        self.instantaneousStrideLength = instantaneousStrideLength
        self.totalDistance = totalDistance
    }

    init(data: Data) throws {
        self.data = data    

        self.flags = RSCMeasurementFlags(value: Int(data[0]))
        let spead: UInt16 = try data.read(fromOffset: 1)
        self.instantaneousSpeed = Measurement(value: Double(spead) / 256.0, unit: .metersPerSecond)

        self.instantaneousCadence = Int(data[3])

        var offset: Int = 4

        if flags.instantaneousStrideLengthPresent {
            let strideLength: UInt16 = try data.read(fromOffset: offset)
            self.instantaneousStrideLength = Measurement(value: Double(strideLength) / 100.0, unit: .meters)
            offset += 2
        } else {
            self.instantaneousStrideLength = nil
        }

        if flags.totalDistancePresent {
            let totalDistance: UInt32 = try data.read(fromOffset: offset)
            self.totalDistance = Measurement(value: Double(totalDistance) / 10.0, unit: .meters)
        } else {
            self.totalDistance = nil
        }
    }
}

class RunningServiceHandler: ServiceHandler, ObservableObject {
    
    private var cancelables = Set<AnyCancellable>()
    
    enum Error: Swift.Error {
        case timeout, noMandatoryCharacteristic, noData, parseError
    }
    
    // MARK: Characteristics
    var rscMeasurement: CBCharacteristic!
    var rscFeature: CBCharacteristic!
    var features: RSCFeature!
    
    var sensorLocation: CBCharacteristic?
    var scControlPoint: CBCharacteristic?
    
    @Published var measurement: RSCMeasurement?
    @Published var error: ReadableError?
    
    override init?(peripheral: Peripheral, service: CBService) {
        guard service.uuid.uuidString == Service.RunningSpeedAndCadence.runningSpeedAndCadence.uuidString else {
            return nil
        }

        super.init(peripheral: peripheral, service: service)
        
        Task {
            try? await prepare()
            enableMeasurement()
        }
    }
    
    func prepare() async throws {
        let characteristicIDs = [
            Characteristic.RscMeasurement.rscMeasurement,
            Characteristic.RscFeature.rscFeature
        ].map { CBUUID(string: $0.uuidString) }
        
        let characteristicsSeq = peripheral.discoverCharacteristics(characteristicIDs, for: service)
            .autoconnect()
            .timeout(.seconds(3), scheduler: DispatchQueue.main, customError: { Error.timeout })
        
        for try await ch in characteristicsSeq.values {
            switch ch.uuid.uuidString {
            case Characteristic.RscMeasurement.rscMeasurement.uuidString:
                rscMeasurement = ch
            case Characteristic.RscFeature.rscFeature.uuidString:
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
        
        self.features = RSCFeature(value: try feauturesData.read() as Int)
        
        if features.multipleSensorLocation {
            let uuid = CBUUID(string: Characteristic.SensorLocation.sensorLocation.uuidString)
            
            self.sensorLocation = try await peripheral.discoverCharacteristics([uuid], for: service)
                .autoconnect()
                .value
        }
        
        if features.sensorCalibrationProcedure {
            let uuid = CBUUID(string: Characteristic.ScControlPoint.scControlPoint.uuidString)
            
            self.scControlPoint = try await peripheral.discoverCharacteristics([uuid], for: service)
                .autoconnect()
                .value
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
            }
            .store(in: &cancelables)
    }
}
