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
    
    // MARK: init
    
    init(data: Data) throws {
        guard data.count >= Self.MinSize else {
            throw DataError.invalidSize(data.count)
        }
        
        let featureFlags = UInt(data.littleEndianBytes(as: UInt8.self))
        let flagsRegister = BitField<Flag>(featureFlags)
        let unit: UnitPressure = flagsRegister.contains(.unit) ? .millimetersOfMercury : .kilopascals
        
        var offset = 1
        let systolicValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        systolicPressure = Measurement<UnitPressure>(value: Double(systolicValue), unit: unit)
        offset += SFloatReserved.byteSize
        let diastolicValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        diastolicPressure = Measurement<UnitPressure>(value: Double(diastolicValue), unit: unit)
        offset += SFloatReserved.byteSize
        let meanArterialValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        meanArterialPressure = Measurement<UnitPressure>(value: Double(meanArterialValue), unit: unit)
        offset += SFloatReserved.byteSize
        
        date = flagsRegister.contains(.timestamp) ? {
            defer {
                offset += Date.DataSize
            }
            return Date(data.subdata(in: offset..<offset + Date.DataSize))
        }() : nil
        
        pulseRate = flagsRegister.contains(.pulseRate) ? {
            let pulseValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
            return Int(pulseValue)
        }() : nil
    }
}

// MARK: - Flags

fileprivate extension BloodPressureMeasurement {
    
    private enum Flag: RegisterValue, Option, CaseIterable {
        case unit, timestamp, pulseRate
    }
}

// MARK: - DataError

extension BloodPressureMeasurement {
    
    enum DataError: LocalizedError, CustomStringConvertible {
        case invalidSize(_ count: Int)
        
        var description: String {
            switch self {
            case .invalidSize(let byteCount):
                return "Data Size of \(byteCount) bytes does not match minimum requirement of \(BloodPressureMeasurement.MinSize) bytes for Blood Pressure Measurement."
            }
        }
        
        var errorDescription: String? {
            description
        }
    }
}
