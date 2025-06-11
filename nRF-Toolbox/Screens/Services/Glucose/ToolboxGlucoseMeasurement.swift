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
    
    private let sensorCode: RegisterValue
    private let locationCode: RegisterValue
    private let statusCode: RegisterValue?
    
    // MARK: init
    
    init?(_ data: Data) {
        let featureFlags = UInt(data.littleEndianBytes(atOffset: 0, as: UInt8.self))
        let flags = BitField<GlucoseMeasurement.Flags>(featureFlags)
        
        self.sequenceNumber = data.littleEndianBytes(atOffset: 1, as: UInt16.self)
        var offset = MemoryLayout<UInt8>.size + MemoryLayout<UInt16>.size
        
        let dateData = data.subdata(in: offset ..< offset + Date.DataSize)
        guard let date = Date(dateData) else { return nil }
        self.timestamp = date
        offset += Date.DataSize
        
        if flags.contains(.timeOffset) {
            let timeOffset = data.littleEndianBytes(atOffset: offset, as: Int16.self)
            offset += MemoryLayout<UInt16>.size
            self.timeOffset = Measurement<UnitDuration>(value: Double(timeOffset), unit: .minutes)
        } else {
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
        
        guard data.canRead(UInt8.self, atOffset: offset) else { return nil }
        let typeAndLocation = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
        offset += MemoryLayout<UInt8>.size
        self.sensorCode = RegisterValue((typeAndLocation & 0xF0) >> 4)
        self.locationCode = RegisterValue(typeAndLocation & 0xF0)
        
        if flags.contains(.statusAnnunciationPresent) {
            guard data.canRead(UInt8.self, atOffset: offset) else { return nil }
            self.statusCode = RegisterValue(data.littleEndianBytes(atOffset: offset, as: UInt8.self))
            offset += MemoryLayout<UInt8>.size
        } else {
            self.statusCode = nil
        }
    }
    
    // MARK: API
    
    func sensorString() -> String {
        if let sensor = GlucoseMeasurement.SensorType(rawValue: sensorCode) {
            return sensor.description
        } else {
            return GlucoseMeasurement.SensorType.reservedDescription(Int(sensorCode))
        }
    }
    
    func locationString() -> String {
        if let location = GlucoseMeasurement.SensorLocation(rawValue: locationCode) {
            return location.description
        } else {
            return GlucoseMeasurement.SensorType.reservedDescription(Int(locationCode))
        }
    }
    
    func statusString() -> String {
        guard let statusCode, let status = GlucoseMeasurement.Status(rawValue: statusCode) else {
            return "Status: \(statusCode.nilDescription)"
        }
        return status.description
    }
    
    func toStringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("E d MMM yyyy HH:mm:ss")
        return dateFormatter.string(from: timestamp)
    }
}

// MARK: - bloodGramsPerMole

public extension Double {
    
    static let bloodGramsPerMole = 64.458
}

// MARK: - CustomStringConvertible

extension ToolboxGlucoseMeasurement: CustomStringConvertible {
    
    var description: String {
        return String(format: "%.2f \(measurement.unit.symbol), Seq.: \(sequenceNumber), Date: \(toStringDate()), Sensor: \(sensorString()), Location: \(locationString()), Status: \(statusString())", measurement.value)
    }
}
