//
//  CyclingServiceViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

// MARK: - CyclingServiceViewModel

final class CyclingServiceViewModel: ObservableObject {
    
    // MARK: Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cscMeasurement: CBCharacteristic!
    private var cscFeature: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "CyclingServiceViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(peripheral: Peripheral, cyclingService: CBService) {
        self.peripheral = peripheral
        self.service = cyclingService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
    
    // MARK: discoverCharacteristics()
    
    func discoverCharacteristics() async throws {
        log.debug(#function)
        let serviceCharacteristics: [Characteristic] = [.cscMeasurement, .cscFeature]
        let discoveredCharacteristics: [CBCharacteristic]
        discoveredCharacteristics = try await peripheral.discoverCharacteristics(serviceCharacteristics.map(\.uuid), for: service).firstValue
        
        for characteristic in discoveredCharacteristics {
            switch characteristic.uuid {
            case .cscMeasurement:
                self.cscMeasurement = characteristic
                log.debug("Found CSC Measurement Characteristic.")
            case .cscFeature:
                self.cscFeature = characteristic
                log.debug("Found CSC Feature Characteristic.")
            default:
                break
            }
        }
        
        guard cscMeasurement != nil, cscFeature != nil else {
            throw CriticalError.noMandatoryCharacteristics
        }
    }
    
    // MARK: startListening()
    
    func startListening() async throws {
        log.debug(#function)
        let cyclingFeatures = try await peripheral.readValue(for: cscFeature).tryMap { [unowned self] data in
            guard let data else {
                throw CriticalError.noData
            }
            self.log.debug("Received Feature Data \(data)")
            return CyclingFeatures(flags: RegisterValue(data[0]))
        }
        .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: { CriticalError.timeout })
        .firstValue
        
        log.debug("Detected \(cyclingFeatures)")
        peripheral.listenValues(for: cscMeasurement)
            .compactMap { try? CyclingCharacteristic($0) }
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    self.log.debug("Finished!")
                case .failure(let error):
                    self.log.error("Error: \(error.localizedDescription)")
                }
            } receiveValue: { [unowned self] update in
                self.log.debug("\(update)")
            }
            .store(in: &cancellables)
        
        // Enable Notifications
        _ = try await peripheral.setNotifyValue(true, for: cscMeasurement).firstValue
    }
}

private extension CBUUID {
    static let cscMeasurement = CBUUID(characteristic: .cscMeasurement)
    static let cscFeature = CBUUID(characteristic: .cscFeature)
}

// MARK: - SupportedServiceViewModel

extension CyclingServiceViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        do {
            try await discoverCharacteristics()
            try await startListening()
        }
        catch let error {
            log.error("Error \(error.localizedDescription)")
            // TODO: Later, I guess.
        }
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}

private extension Flag {
    static let wheelData: Flag = 0x01
    static let crankData: Flag = 0x02
}

// MARK: - CyclingCharacteristic

struct CyclingCharacteristic {
    
    typealias WheelRevolutionAndTime = (revolution: Int, time: Double)
    
    let wheelRevolutionsAndTime: WheelRevolutionAndTime?
    let crankRevolutionsAndTime: WheelRevolutionAndTime?
    
    static let zero = CyclingCharacteristic(wheelRevolutionsAndTime: (0, 0.0), crankRevolutionsAndTime: (0, 0.0))
    
    init(wheelRevolutionsAndTime: (Int, Double)?, crankRevolutionsAndTime: (Int, Double)?) {
        self.wheelRevolutionsAndTime = wheelRevolutionsAndTime
        self.crankRevolutionsAndTime = crankRevolutionsAndTime
    }
    
    init(_ data: Data) throws {
        let flags: UInt8 = try data.read()
        
        wheelRevolutionsAndTime = try Flag.isAvailable(bits: flags, flag: .wheelData) ? {
                (
                    Int(try data.read(fromOffset: 1) as UInt32),
                    Double(try data.read(fromOffset: 5) as UInt16)
                )
            }() : nil
        
        let crankOffset: (Int, Int) = Flag.isAvailable(bits: flags, flag: .wheelData) ? (7, 9) : (1, 3)
        
        crankRevolutionsAndTime = try Flag.isAvailable(bits: flags, flag: .crankData) ? {
                (
                    Int(try data.read(fromOffset: crankOffset.0) as UInt16),
                    Double(try data.read(fromOffset: crankOffset.1) as UInt16)
                )
            }() : nil
    }
    
    func travelDistance(with wheelCircumference: Double) -> Measurement<UnitLength>? {
        wheelRevolutionsAndTime.map { Measurement<UnitLength>(value: Double($0.revolution) * wheelCircumference, unit: .meters) }
    }
    
    func distance(_ oldCharacteristic: CyclingCharacteristic, wheelCircumference: Double) -> Measurement<UnitLength>? {
        wheelRevolutionDiff(oldCharacteristic)
            .flatMap { Measurement<UnitLength>(value: Double($0) * wheelCircumference, unit: .meters) }
    }
    
    func gearRatio(_ oldCharacteristic: CyclingCharacteristic) -> Double? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(oldCharacteristic), let crankRevolutionDiff = crankRevolutionDiff(oldCharacteristic), crankRevolutionDiff != 0 else {
            return nil
        }
        return Double(wheelRevolutionDiff) / Double(crankRevolutionDiff)
    }
    
    func speed(_ oldCharacteristic: CyclingCharacteristic, wheelCircumference: Double) -> Measurement<UnitSpeed>? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(oldCharacteristic), let wheelEventTime = wheelRevolutionsAndTime?.time, let oldWheelEventTime = oldCharacteristic.wheelRevolutionsAndTime?.time else {
            return nil
        }
        
        var wheelEventTimeDiff = wheelEventTime - oldWheelEventTime
        guard wheelEventTimeDiff > 0 else {
            return nil
        }
        
        wheelEventTimeDiff /= 1024
        let speed = (Double(wheelRevolutionDiff) * wheelCircumference) / wheelEventTimeDiff
        return Measurement<UnitSpeed>(value: speed, unit: .milesPerHour)
    }
    
    func cadence(_ oldCharacteristic: CyclingCharacteristic) -> Int? {
        guard let crankRevolutionDiff = crankRevolutionDiff(oldCharacteristic), let crankEventTimeDiff = crankEventTimeDiff(oldCharacteristic), crankEventTimeDiff > 0 else {
            return nil
        }
        
        return Int(Double(crankRevolutionDiff) / crankEventTimeDiff * 60.0)
    }
    
    private func wheelRevolutionDiff(_ oldCharacteristic: CyclingCharacteristic) -> Int? {
        guard let oldWheelRevolution = oldCharacteristic.wheelRevolutionsAndTime?.revolution, let wheelRevolution = wheelRevolutionsAndTime?.revolution else {
            return nil
        }
        guard oldWheelRevolution != 0 else { return 0 }
        return wheelRevolution - oldWheelRevolution
    }
    
    private func crankRevolutionDiff(_ old: CyclingCharacteristic) -> Int? {
        guard let crankRevolution = crankRevolutionsAndTime?.revolution, let oldCrankRevolution = old.crankRevolutionsAndTime?.revolution else {
            return nil
        }
        
        return crankRevolution - oldCrankRevolution
    }
    
    private func crankEventTimeDiff(_ old: CyclingCharacteristic) -> Double? {
        guard let crankEventTime = crankRevolutionsAndTime?.time, let oldCrankEventTime = old.crankRevolutionsAndTime?.time else {
            return nil
        }
        return (crankEventTime - oldCrankEventTime) / 1024.0
    }
}


