//
//  CyclingData.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let wheelData: Flag = 0x01
    static let crankData: Flag = 0x02
}

// MARK: - CyclingData

struct CyclingData {
    
    typealias WheelRevolutionAndTime = (revolution: Int, time: Double)
    
    let wheelRevolutionsAndTime: WheelRevolutionAndTime?
    let crankRevolutionsAndTime: WheelRevolutionAndTime?
    
    static let zero = CyclingData(wheelRevolutionsAndTime: (0, 0.0), crankRevolutionsAndTime: (0, 0.0))
    
    // MARK: init
    
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
    
    func travelDistance(with wheelLength: Measurement<UnitLength>) -> Measurement<UnitLength>? {
        wheelRevolutionsAndTime.map {
            Measurement<UnitLength>(value: Double($0.revolution) * wheelLength.value, unit: wheelLength.unit)
                .converted(to: .kilometers)
        }
    }
    
    func distance(_ oldCharacteristic: CyclingData, wheelLength: Measurement<UnitLength>) -> Measurement<UnitLength>? {
        wheelRevolutionDiff(oldCharacteristic)
            .flatMap {
                Measurement<UnitLength>(value: Double($0) * wheelLength.value, unit: wheelLength.unit)
            }
    }
    
    func gearRatio(_ oldCharacteristic: CyclingData) -> Double? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(oldCharacteristic),
              let crankRevolutionDiff = crankRevolutionDiff(oldCharacteristic),
              crankRevolutionDiff != 0 else {
            return nil
        }
        return Double(wheelRevolutionDiff) / Double(crankRevolutionDiff)
    }
    
    func speed(_ oldCharacteristic: CyclingData, wheelLength: Measurement<UnitLength>) -> Measurement<UnitSpeed>? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(oldCharacteristic),
              let wheelEventTime = wheelRevolutionsAndTime?.time,
              let oldWheelEventTime = oldCharacteristic.wheelRevolutionsAndTime?.time else {
            return nil
        }
        
        var wheelEventTimeDiff = wheelEventTime - oldWheelEventTime
        guard wheelEventTimeDiff > 0 else {
            return nil
        }
        
        wheelEventTimeDiff /= 1024
//        let speed = (Double(wheelRevolutionDiff) * wheelLength) / wheelEventTimeDiff
//        return Measurement<UnitSpeed>(value: speed.value, unit: .milesPerHour)
        return Measurement<UnitSpeed>(value: (Double(wheelRevolutionDiff) * wheelLength.value) / wheelEventTimeDiff, unit: .kilometersPerHour)
    }
    
    func cadence(_ oldCharacteristic: CyclingData) -> Int? {
        guard let crankRevolutionDiff = crankRevolutionDiff(oldCharacteristic),
              let crankEventTimeDiff = crankEventTimeDiff(oldCharacteristic),
              crankEventTimeDiff > 0 else {
            return nil
        }
        
        return Int(Double(crankRevolutionDiff) / crankEventTimeDiff * 60.0)
    }
    
    // MARK: - Private
    
    private func wheelRevolutionDiff(_ oldCharacteristic: CyclingData) -> Int? {
        guard let oldWheelRevolution = oldCharacteristic.wheelRevolutionsAndTime?.revolution,
              let wheelRevolution = wheelRevolutionsAndTime?.revolution else {
            return nil
        }
        guard oldWheelRevolution != 0 else { return 0 }
        return wheelRevolution - oldWheelRevolution
    }
    
    private func crankRevolutionDiff(_ old: CyclingData) -> Int? {
        guard let crankRevolution = crankRevolutionsAndTime?.revolution,
              let oldCrankRevolution = old.crankRevolutionsAndTime?.revolution else {
            return nil
        }
        
        return crankRevolution - oldCrankRevolution
    }
    
    private func crankEventTimeDiff(_ old: CyclingData) -> Double? {
        guard let crankEventTime = crankRevolutionsAndTime?.time,
              let oldCrankEventTime = old.crankRevolutionsAndTime?.time else {
            return nil
        }
        return (crankEventTime - oldCrankEventTime) / 1024.0
    }
}
