//
//  GlucoseMeasurement.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 9/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - ToolboxGlucoseMeasurement

struct ToolboxGlucoseMeasurement {
    
    // MARK: Properties
    
    let sequenceNumber: Int
    let timestamp: Date
    let timeOffset: Measurement<UnitDuration>?
    let measurement: Measurement<UnitConcentrationMass>
    
    // MARK: init
    
    init?(_ data: Data) {
        let featureFlags = UInt(data.littleEndianBytes(atOffset: 0, as: UInt8.self))
        let flags = BitField<GlucoseMeasurement.Flags>(featureFlags)
        
        self.sequenceNumber = data.littleEndianBytes(atOffset: 1, as: UInt16.self)
        var offset = MemoryLayout<UInt8>.size + MemoryLayout<UInt16>.size
        
        let dateData = data.subdata(in: offset ..< offset + Date.DataSize)
        guard let date = Date(dateData) else { return nil }
        offset += Date.DataSize
        
        if flags.contains(.timeOffset) {
            let timeOffset = data.littleEndianBytes(atOffset: offset, as: Int16.self)
            offset += MemoryLayout<UInt16>.size
            self.timestamp = date
            self.timeOffset = Measurement<UnitDuration>(value: Double(timeOffset), unit: .minutes)
        } else {
            self.timestamp = date
            self.timeOffset = nil
        }
        
        guard flags.contains(.typeAndLocation) else { return nil }
        let value = Float(asSFloat: data.subdata(in: offset..<offset+SFloatReserved.byteSize))
        offset += SFloatReserved.byteSize
        if flags.contains(.concentrationUnit) {
            measurement = Measurement<UnitConcentrationMass>(value: Double(value * 1000), unit: .gramsPerLiter)
        } else {
            measurement = Measurement<UnitConcentrationMass>(value: Double(value), unit: .millimolesPerLiter(withGramsPerMole: .bloodGramsPerMole))
        }
    }
}

// MARK: - bloodGramsPerMole

public extension Double {
    
    static let bloodGramsPerMole = 64.458
}

// MARK: - CustomStringConvertible

extension ToolboxGlucoseMeasurement: CustomStringConvertible {
    
    var description: String {
        return String(format: "%.2f \(measurement.unit.symbol), Seq.: \(sequenceNumber)", measurement.value)
    }
}
