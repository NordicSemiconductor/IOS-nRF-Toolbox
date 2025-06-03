//
//  BloodPressureCharacteristic.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 3/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - BloodPressureCharacteristic

struct BloodPressureCharacteristic {
    
    // MARK: Properties
    
    let systolicPressure: Measurement<UnitPressure>
    let diastolicPressure: Measurement<UnitPressure>
    let meanArterialPressure: Measurement<UnitPressure>
    let date: Date?
    let pulseRate: Int?
    
    // MARK: init
    
    init(data: Data) throws {
        let featureFlags = UInt(data.littleEndianBytes(as: UInt8.self))
        let flagsRegister = BitField<BloodPressureMeasurementFlags>(featureFlags)
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
            return Date(data.suffix(from: offset))
        }() : nil
        
        pulseRate = flagsRegister.contains(.pulseRate) ? {
            let pulseValue = Float(asSFloat: data.suffix(from: offset))
            return Int(pulseValue)
        }() : nil
    }
}

// MARK: - BloodPressureMeasurementFlags

private enum BloodPressureMeasurementFlags: RegisterValue, Option, CaseIterable {
    
    case unit, timestamp, pulseRate
}
