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
import SwiftUI

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

@MainActor
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
    
    @Published var instantaneousSpeed: SomeValue = SomeValue(systemName: "hare.fill", text: "Instantaneous Speed", value: "--", isActive: false, color: .green)
    @Published var instantaneousCadence: SomeValue = SomeValue(systemName: "shoeprints.fill", text: "Instantaneous Cadence", value: "--", isActive: false, color: .blue)
    @Published var instantaneousStrideLength: SomeValue = SomeValue(systemName: "ruler.fill", text: "Instantaneous Stride Length", value: "--", isActive: false, color: .purple)
    @Published var totalDistance: SomeValue = SomeValue(systemName: "map.fill", text: "Total Distance", value: "--", isActive: false, color: .cyan)
    
    // MARK: Sensor Location
    @Published var sensorLocationValue: SensorLocation?
    @Published var readingSersorLocation: Bool = false 
    
    override init?(peripheral: Peripheral, service: CBService) {
        guard service.uuid.uuidString == Service.RunningSpeedAndCadence.runningSpeedAndCadence.uuidString else {
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
        
        let data = try feauturesData.read() as UInt16
        self.features = RSCFeature(value: Int(data))
        
        if features.multipleSensorLocation {
            self.sensorLocation = try await peripheral.discoverCharacteristics([.sensorLocation], for: service)
                .autoconnect()
                .value
            
            self.sensorLocationValue = .unknown
        }
        
        if features.sensorCalibrationProcedure {
            self.scControlPoint = try await peripheral.discoverCharacteristics([.scControlPoint], for: service)
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
            throw Error.noMandatoryCharacteristic
        }
        
        guard let v = try await peripheral.readValue(for: sensorLocation).value else {
            throw Error.noData
        }
        
        self.sensorLocationValue = SensorLocation(data: v)
    }
}
