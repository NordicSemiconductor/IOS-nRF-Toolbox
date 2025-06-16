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
    
    init(wheelData: WheelDataPoint = .zero, crankData: CrankDataPoint = .zero) {
        self.wheelData = wheelData
        self.crankData = crankData
    }
    
    init(_ data: Data) throws {
        guard data.canRead(UInt8.self, atOffset: 0) else {
            throw CriticalError.noData
        }
        let flagsByte = data.littleEndianBytes(as: UInt8.self)
        let flags = BitField<CyclingDataFlag>(RegisterValue(flagsByte))
        var offset = MemoryLayout<UInt8>.size
        if flags.contains(.wheelData) {
            let wheelSubdata = data.subdata(in: offset..<min(offset + WheelDataPoint.DataSize, data.count))
            guard let wheelData = WheelDataPoint(wheelSubdata) else {
                throw CriticalError.noData
            }
            self.wheelData = wheelData
            offset += WheelDataPoint.DataSize
        } else {
            self.wheelData = nil
        }
        
        if flags.contains(.crankData) {
            let crankSubdata = data.subdata(in: offset..<min(offset + CrankDataPoint.DataSize, data.count))
            guard let crankData = CrankDataPoint(crankSubdata) else {
                throw CriticalError.noData
            }
            self.crankData = crankData
            offset += CrankDataPoint.DataSize
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
    
    func distance(_ currentData: CyclingData, wheelLength: Measurement<UnitLength>) -> Measurement<UnitLength>? {
        wheelRevolutionDiff(currentData)
            .flatMap {
                Measurement<UnitLength>(value: Double($0) * wheelLength.value, unit: wheelLength.unit)
            }
    }
    
    func gearRatio(_ currentData: CyclingData) -> Double? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(currentData),
              let crankRevolutionDiff = crankRevolutionDiff(currentData),
              crankRevolutionDiff != 0 else {
            return nil
        }
        return Double(wheelRevolutionDiff) / Double(crankRevolutionDiff)
    }
    
    func speed(_ currentData: CyclingData, wheelLength: Measurement<UnitLength>) -> Measurement<UnitSpeed>? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(currentData),
              let wheelEventTime = wheelData?.time,
              let oldWheelEventTime = currentData.wheelData?.time else {
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
    
    func cadence(_ currentData: CyclingData) -> Int? {
        guard let crankRevolutionDiff = crankRevolutionDiff(currentData),
              let crankEventTimeDiff = crankEventTimeDiff(currentData),
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
