//
//  BloodPressureMeasurement.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 3/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - BloodPressureMeasurement

struct BloodPressureMeasurement {
    
    // MARK: Constant
    
    private static let MinSize = MemoryLayout<UInt8>.size + 3 * SFloatReserved.byteSize
    
    // MARK: Properties
    
    let systolicPressure: Measurement<UnitPressure>
    let diastolicPressure: Measurement<UnitPressure>
    let meanArterialPressure: Measurement<UnitPressure>
    let date: Date?
    let pulseRate: Int?
    let userID: UInt8?
    let status: BitField<MeasurementStatus>?
    
    // MARK: init
    
    init(data: Data) throws {
        let reader = DataReader(data: data)
        
        let featureFlags = UInt(try reader.read(UInt8.self))
        let flagsRegister = BitField<MeasurementFlag>(featureFlags)
        let unit: UnitPressure = flagsRegister.contains(.unit) ? .kilopascals : .millimetersOfMercury
        
        systolicPressure = Measurement<UnitPressure>(value: Double(try reader.readSFloat()), unit: unit)
        diastolicPressure = Measurement<UnitPressure>(value: Double(try reader.readSFloat()), unit: unit)
        meanArterialPressure = Measurement<UnitPressure>(value: Double(try reader.readSFloat()), unit: unit)
        
        date = flagsRegister.contains(.timestamp) ? try reader.readDate() : nil
        pulseRate = flagsRegister.contains(.pulseRate) ? Int(try reader.readSFloat()) : nil
        userID = flagsRegister.contains(.userID) ? try reader.read(UInt8.self) : nil
        status = flagsRegister.contains(.measurementStatus) ? BitField<MeasurementStatus>(RegisterValue(try reader.read(UInt16.self))) : nil
    }
}

// MARK: - Feature

extension BloodPressureMeasurement {
    
    enum Feature: RegisterValue, Option, Codable, CustomStringConvertible {
        case movementDetection = 0
        case cuffFitDetection = 1
        case irregularPulseDetection = 2
        case pulseRateRangeDetection = 3
        case measurementPositionDetection = 4
        case multipleBond = 5
        case e2e_crc = 6
        case userDataService = 7
        case userFacingTime = 8
        
        public var description: String {
            switch self {
            case .movementDetection:
                return "Movement detection"
            case .cuffFitDetection:
                return "Cuff fit detection"
            case .irregularPulseDetection:
                return "Irregular pulse detection"
            case .pulseRateRangeDetection:
                return "Pulse rate range detection"
            case .measurementPositionDetection:
                return "Measurement position detection"
            case .multipleBond:
                return "Multiple bond"
            case .e2e_crc:
                return "E2E-CRC"
            case .userDataService:
                return "User data service"
            case .userFacingTime:
                return "User facing time"
            }
        }
    }
}
