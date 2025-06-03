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
    
    // MARK: Proeprties
    
    let cuffPressure: Measurement<UnitPressure>
    
    // MARK: init
    
    init(data: Data) throws {
        let featureFlags = UInt(data.littleEndianBytes(as: UInt8.self))
        let flagsRegister = BitField<Flag>(featureFlags)
        let unit: UnitPressure = flagsRegister.contains(.unit) ? .millimetersOfMercury : .kilopascals
        
        let cuffPressureValue = Float(asSFloat: data.subdata(in: 1..<1 + SFloatReserved.byteSize))
        cuffPressure = Measurement<UnitPressure>(value: Double(cuffPressureValue), unit: unit)
    }
}

// MARK: - Flags

extension CuffPressureMeasurement {
    
    private enum Flag: RegisterValue, Option, CaseIterable {
        case unit
    }
}
