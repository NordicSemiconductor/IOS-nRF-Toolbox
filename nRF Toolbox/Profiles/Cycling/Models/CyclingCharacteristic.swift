//
//  CyclingCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let wheelData: Flag = 0x01
    static let crankData: Flag = 0x02
}

struct CyclingCharacteristic {
    
    typealias WheelRevolutionAndTime = (revolution: Int, time: Double)
    
    let wheelRevolutionsAndTime: WheelRevolutionAndTime?
    let crankRevolutionsAndTime: WheelRevolutionAndTime?
    
    static let zero = CyclingCharacteristic(wheelRevolutionsAndTime: (0, 0.0), crankRevolutionsAndTime: (0, 0.0))
    
    init(wheelRevolutionsAndTime: (Int, Double)?, crankRevolutionsAndTime: (Int, Double)?) {
        self.wheelRevolutionsAndTime = wheelRevolutionsAndTime
        self.crankRevolutionsAndTime = crankRevolutionsAndTime
    }
    
    init(data: Data) {
        let flags: UInt8 = data.read()
        
        wheelRevolutionsAndTime = Flag.isAvailable(bits: flags, flag: .wheelData) ? {
                (
                    Int(data.read(fromOffset: 1) as UInt32),
                    Double(data.read(fromOffset: 5) as UInt16)
                )
            }() : nil
        
        let crankOffset: (Int, Int) = Flag.isAvailable(bits: flags, flag: .wheelData) ? (7, 9) : (1, 3)
        
        crankRevolutionsAndTime = Flag.isAvailable(bits: flags, flag: .crankData) ? {
                (
                    Int(data.read(fromOffset: crankOffset.0) as UInt16),
                    Double(data.read(fromOffset: crankOffset.1) as UInt16)
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
