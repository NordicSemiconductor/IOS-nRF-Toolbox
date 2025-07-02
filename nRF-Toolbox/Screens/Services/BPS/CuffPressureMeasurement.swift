//
//  CuffPressureCharacteristic.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 3/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CuffPressureMeasurement

struct CuffPressureMeasurement {
    
    // MARK: Constant
    
    private static let MinSize = MemoryLayout<UInt8>.size + 3 * SFloatReserved.byteSize
    
    // MARK: Proeprties
    
    let cuffPressure: Measurement<UnitPressure>
    let diastolic: Measurement<UnitPressure>
    let meanArterialPressure: Measurement<UnitPressure>
    
    let timestamp: Date?
    let pulseRate: Int?
    let userID: UInt8?
    let status: BitField<Status>?
    
    // MARK: init
    
    init(data: Data) throws {
        guard data.count >= Self.MinSize else {
            throw BloodPressureMeasurement.DataError.invalidSize(data.count)
        }
        
        let featureFlags = UInt(data.littleEndianBytes(as: UInt8.self))
        let flagsRegister = BitField<Flag>(featureFlags)
        let unit: UnitPressure = flagsRegister.contains(.unit) ? .millimetersOfMercury : .kilopascals
        var offset = MemoryLayout<UInt8>.size
        
        let cuffPressureValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        cuffPressure = Measurement<UnitPressure>(value: Double(cuffPressureValue), unit: unit)
        offset += SFloatReserved.byteSize
        
        let diastolicValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        diastolic = Measurement<UnitPressure>(value: Double(diastolicValue), unit: unit)
        offset += SFloatReserved.byteSize
        
        let meanArterialValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        meanArterialPressure = Measurement<UnitPressure>(value: Double(meanArterialValue), unit: unit)
        offset += SFloatReserved.byteSize
        
        timestamp = flagsRegister.contains(.timestamp) ? {
            defer {
                offset += Date.DataSize
            }
            return Date(data.subdata(in: offset..<offset + Date.DataSize))
        }() : nil
        
        pulseRate = flagsRegister.contains(.pulseRate) ? {
            defer {
                offset += SFloatReserved.byteSize
            }
            let pulseValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
            return Int(pulseValue)
        }() : nil
        
        userID = flagsRegister.contains(.userID) ? {
            defer {
                offset += MemoryLayout<UInt8>.size
            }
            return try? data.read(fromOffset: offset)
        }() : nil
        
        status = flagsRegister.contains(.measurementStatus) ? {
            BitField<Status>(RegisterValue(data.littleEndianBytes(atOffset: offset, as: UInt16.self)))
        }() : nil
    }
}

// MARK: - Flags

extension CuffPressureMeasurement {
    
    private enum Flag: RegisterValue, Option, CaseIterable {
        case unit
        case timestamp
        case pulseRate
        case userID
        case measurementStatus
    }
}

// MARK: - Status

extension CuffPressureMeasurement {
    
    enum Status: RegisterValue, Option, CustomStringConvertible {
        case bodyMovement
        case cuffFitLoose
        case irregularPulse
        case pulseRateAboveUpperLimit
        case pulseRateLessThanLimitOrReserved // If bit is zero, it means "Pulse rate is less than lower limit"
        case improperPosition
        
        var description: String {
            switch self {
            case .bodyMovement:
                return "Body movement"
            case .cuffFitLoose:
                return "Cuff fit too loose"
            case .irregularPulse:
                return "Irregular pulse"
            case .pulseRateAboveUpperLimit:
                return "Pulse rate exceeds upper limit"
            case .pulseRateLessThanLimitOrReserved:
                return "Reserved for future use"
            case .improperPosition:
                return "Improper measurement position"
            }
        }
    }
}
