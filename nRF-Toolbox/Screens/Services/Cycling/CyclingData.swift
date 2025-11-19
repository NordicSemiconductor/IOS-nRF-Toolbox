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
    case wheelData, crankData
}

// MARK: - CyclingData

struct CyclingData {
    
    // MARK: Properties
    
    let wheelData: WheelDataPoint?
    let crankData: CrankDataPoint?
    
    func travelDistance(with wheelLength: Measurement<UnitLength>) -> Measurement<UnitLength>? {
        guard let wheelData else { return nil }
        return Measurement<UnitLength>(value: Double(wheelData.revolutions) * wheelLength.value,
                                       unit: wheelLength.unit)
            .converted(to: .kilometers)
    }
    
    func distance(_ previousData: CyclingData, wheelLength: Measurement<UnitLength>) -> Measurement<UnitLength>? {
        wheelRevolutionDiff(previousData)
            .flatMap {
                Measurement<UnitLength>(value: Double($0) * wheelLength.value, unit: wheelLength.unit)
            }
    }
    
    func gearRatio(_ previous: CyclingData) -> Double? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(previous),
              let crankRevolutionDiff = crankRevolutionDiff(previous),
              crankRevolutionDiff != 0 else {
            return nil
        }
        return Double(wheelRevolutionDiff) / Double(crankRevolutionDiff)
    }
    
    func speed(_ previousData: CyclingData, wheelLength: Measurement<UnitLength>) -> Measurement<UnitSpeed>? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(previousData),
              let wheelEventTime = wheelData?.time,
              let oldWheelEventTime = previousData.wheelData?.time else {
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
    
    func cadence(_ previousData: CyclingData) -> Int? {
        guard let crankRevolutionDiff = crankRevolutionDiff(previousData),
              let crankEventTimeDiff = crankEventTimeDiff(previousData),
              crankEventTimeDiff > 0 else {
            return nil
        }
        
        return Int(Double(crankRevolutionDiff) / crankEventTimeDiff * 60.0)
    }
    
    // MARK: - Private
    
    private func wheelRevolutionDiff(_ previousData: CyclingData) -> Int? {
        guard let oldWheelRevolutions = previousData.wheelData?.revolutions,
              let wheelRevolutions = wheelData?.revolutions else {
            return nil
        }
        return wheelRevolutions - oldWheelRevolutions
    }
    
    private func crankRevolutionDiff(_ previousData: CyclingData) -> Int? {
        guard let crankRevolution = crankData?.revolutions,
              let oldCrankRevolution = previousData.crankData?.revolutions else {
            return nil
        }
        
        return crankRevolution - oldCrankRevolution
    }
    
    private func crankEventTimeDiff(_ preveiousData: CyclingData) -> Double? {
        guard let crankEventTime = crankData?.time,
              let oldCrankEventTime = preveiousData.crankData?.time else {
            return nil
        }
        return crankEventTime.value - oldCrankEventTime.value
    }
}

extension CyclingData {
    
    static let zero = CyclingData()
    
    init(wheelData: WheelDataPoint = .zero, crankData: CrankDataPoint = .zero) {
        self.wheelData = wheelData
        self.crankData = crankData
    }
    
    init(_ data: Data) throws {
        let reader = DataReader(data: data)
        
        let flagsValue = UInt(try reader.read(UInt8.self))
        let flags = BitField<CyclingDataFlag>(RegisterValue(flagsValue))
        
        wheelData = flags.contains(.wheelData) ? try WheelDataPoint(reader.subdata(WheelDataPoint.DataSize)) : nil
        crankData = flags.contains(.crankData) ? try CrankDataPoint(reader.subdata(CrankDataPoint.DataSize)) : nil
        
        if crankData == nil && wheelData == nil {
            throw ServiceError.noData
        }
    }
}
