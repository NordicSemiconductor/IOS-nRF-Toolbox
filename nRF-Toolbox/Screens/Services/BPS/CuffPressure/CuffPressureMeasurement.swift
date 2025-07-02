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
    let status: BitField<MeasurementStatus>?
    
    // MARK: init
    
    init(data: Data) throws {
        guard data.count >= Self.MinSize else {
            throw BloodPressureMeasurement.DataError.invalidSize(data.count)
        }
        
        let featureFlags = UInt(data.littleEndianBytes(as: UInt8.self))
        let flagsRegister = BitField<MeasurementFlag>(featureFlags)
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
            BitField<MeasurementStatus>(RegisterValue(data.littleEndianBytes(atOffset: offset, as: UInt16.self)))
        }() : nil
    }
}
