//
//  CyclingData.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CyclingDataFlag

enum CyclingDataFlag: RegisterValue, Option {
    case wheelData = 0
    case crankData = 1
}

// MARK: - CyclingData

struct CyclingData {
    
    // MARK: Properties
    
    let wheelData: WheelDataPoint?
    let crankData: CrankDataPoint?
    
    static let zero = CyclingData()
    
    // MARK: init
    
    init() {
        self.wheelData = .zero
        self.crankData = .zero
    }
    
    init(_ data: Data) throws {
        let flagsByte = data.littleEndianBytes(as: UInt8.self)
        let flags = BitField<CyclingDataFlag>(RegisterValue(flagsByte))
        
        if flags.contains(.wheelData) {
            guard let wheelData = WheelDataPoint(data) else {
                throw CriticalError.noData
            }
            self.wheelData = wheelData
        } else {
            self.wheelData = nil
        }
        
        if flags.contains(.crankData) {
            guard let crankData = CrankDataPoint(data) else {
                throw CriticalError.noData
            }
            self.crankData = crankData
        } else {
            self.crankData = nil
        }
    }
    
    func travelDistance(with wheelLength: Measurement<UnitLength>) -> Measurement<UnitLength>? {
        guard let wheelData else { return nil }
        return Measurement<UnitLength>(value: Double(wheelData.revolutions) * wheelLength.value,
                                       unit: wheelLength.unit)
            .converted(to: .kilometers)
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
              let wheelEventTime = wheelData?.time,
              let oldWheelEventTime = oldCharacteristic.wheelData?.time else {
            return nil
        }
        
        let wheelEventTimeDiff = wheelEventTime - oldWheelEventTime
        guard wheelEventTimeDiff.value > .zero else {
            return nil
        }
        
        let wheelLengthMeters = wheelLength.converted(to: .meters)
        let distanceTravelled = Measurement<UnitLength>(value: Double(wheelRevolutionDiff) * wheelLengthMeters.value, unit: .meters)
        let speed = distanceTravelled.value / wheelEventTimeDiff
        return Measurement<UnitSpeed>(value: speed.value, unit: .metersPerSecond)
            .converted(to: .kilometersPerHour)
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
        guard let oldWheelRevolutions = oldCharacteristic.wheelData?.revolutions,
              let wheelRevolutions = wheelData?.revolutions else {
            return nil
        }
        guard oldWheelRevolutions != 0 else { return 0 }
        return wheelRevolutions - oldWheelRevolutions
    }
    
    private func crankRevolutionDiff(_ old: CyclingData) -> Int? {
        guard let crankRevolution = crankData?.revolutions,
              let oldCrankRevolution = old.crankData?.revolutions else {
            return nil
        }
        
        return crankRevolution - oldCrankRevolution
    }
    
    private func crankEventTimeDiff(_ old: CyclingData) -> Double? {
        guard let crankEventTime = crankData?.time,
              let oldCrankEventTime = old.crankData?.time else {
            return nil
        }
        return (crankEventTime - oldCrankEventTime) / 1024.0
    }
}
