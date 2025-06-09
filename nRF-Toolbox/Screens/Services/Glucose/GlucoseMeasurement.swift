//
//  GlucoseMeasurement.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 9/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - GlucoseMeasurement

struct GlucoseMeasurement {
    
    //MARK: Properties
    
    let sequenceNumber: Int
    let timestamp: Date
    let timeOffset: Int?
    let measurement: Measurement<UnitConcentrationMass>?
    
    // MARK: init
    
    init?(_ data: Data) {
        let featureFlags = UInt(data.littleEndianBytes(atOffset: 0, as: UInt8.self))
        let flags = BitField<GlucoseMeasurement.Flags>(featureFlags)
        
        self.sequenceNumber = data.littleEndianBytes(atOffset: 1, as: UInt16.self)
        var offset = MemoryLayout<UInt8>.size + MemoryLayout<UInt16>.size
        
        let dateData = data.subdata(in: offset ..< offset + Date.DataSize)
        if let date = Date(dateData) {
            print(date)
        }
        offset += Date.DataSize
        
        if flags.contains(.timeOffset) {
            self.timeOffset = data.littleEndianBytes(atOffset: offset, as: Int16.self)
            offset += MemoryLayout<UInt16>.size
        } else {
            self.timeOffset = nil
        }
        self.timestamp = .now
        
        guard flags.contains(.typeAndLocation) else { return nil }
        let value = Float(asSFloat: data.subdata(in: offset..<offset+SFloatReserved.byteSize))
        offset += SFloatReserved.byteSize
        if flags.contains(.concentrationUnit) {
            measurement = Measurement<UnitConcentrationMass>(value: Double(value * 1000), unit: .gramsPerLiter)
        } else {
            measurement = Measurement<UnitConcentrationMass>(value: Double(value), unit: .millimolesPerLiter(withGramsPerMole: 64.458))
        }
    }
}

// MARK: - Flags

extension GlucoseMeasurement {
    
    enum Flags: RegisterValue, Option, CaseIterable {
        
        case timeOffset, typeAndLocation, concentrationUnit, statusAnnunciationPresent
        case contextInfoFollows
    }
}
