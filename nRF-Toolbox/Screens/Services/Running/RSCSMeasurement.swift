//
//  RSCSMeasurement.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 29/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - RSCSMeasurement
    
public struct RSCSMeasurement {
    
    // MARK: Properties
    
    public var flags: BitField<RSCSFeature>

    /// Instantaneous Speed. 256 units = 1 meter/second
    public var instantaneousSpeed: Measurement<UnitSpeed>

    /// Instantaneous Cadence. 1 unit = 1 stride/minute
    public var instantaneousCadence: Int

    /// Instantaneous Stride Length. 100 units = 1 meter
    public var instantaneousStrideLength: Int?

    /// Total Distance. 1 unit = 1 meter
    public var totalDistance: Measurement<UnitLength>?
    
    // MARK: init
    
    public init(flags: BitField<RSCSFeature>, instantaneousSpeed: Double, instantaneousCadence: Int, instantaneousStrideLength: Int?, totalDistance: Double?) {
        self.flags = flags
        self.instantaneousSpeed = Measurement<UnitSpeed>(value: instantaneousSpeed, unit: .metersPerSecond)
        self.instantaneousCadence = instantaneousCadence
        self.instantaneousStrideLength = instantaneousStrideLength
        if let totalDistance {
            self.totalDistance = Measurement<UnitLength>(value: totalDistance, unit: .meters)
        } else {
            self.totalDistance = nil
        }
    }

    public init(from data: Data) {
        let flagsValue = data.littleEndianBytes(as: UInt8.self)
        flags = BitField<RSCSFeature>(RegisterValue(flagsValue))

        var offset = MemoryLayout<UInt8>.size
        // 256 units == 1 meter/second
        let speedUnits = data.littleEndianBytes(atOffset: offset, as: UInt16.self)
        let speedInMetersPerSecond = Double(speedUnits) / 256.0
        instantaneousSpeed = Measurement<UnitSpeed>(value: speedInMetersPerSecond, unit: .metersPerSecond)
        offset += MemoryLayout<UInt16>.size
        
        instantaneousCadence = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
        offset += MemoryLayout<UInt8>.size

        if flags.contains(.instantaneousStrideLengthMeasurement) {
            instantaneousStrideLength = data.littleEndianBytes(atOffset: offset, as: UInt16.self)
            offset += MemoryLayout<UInt16>.size
        } else {
            instantaneousStrideLength = nil
        }

        if flags.contains(.totalDistanceMeasurement) {
            let distanceUnits = data.littleEndianBytes(atOffset: offset, as: UInt32.self)
            // 1 distance unit == 1 meter.
            totalDistance = Measurement<UnitLength>(value: Double(distanceUnits), unit: .meters)
            offset += MemoryLayout<UInt32>.size
        } else {
            totalDistance = nil
        }
    }

    // MARK: Data
    
    public func toData() -> Data {
        var data = Data()

        data.append(flags.data(clippedTo: UInt8.self))
        // 256 units == 1 meter/second
        let instantSpeedUnits = instantaneousSpeed.value * 256.0
        data = data.appendedValue(UInt16(instantSpeedUnits))
        data = data.appendedValue(UInt8(instantaneousCadence))
        
        if flags.contains(.instantaneousStrideLengthMeasurement) {
            data = data.appendedValue(UInt16(instantaneousStrideLength!))
        }

        if flags.contains(.totalDistanceMeasurement), let totalDistance {
            // 1 meter == 1 distance unit.
            data = data.appendedValue(UInt32(totalDistance.value))
        }

        return data
    }
}

fileprivate extension Data {
    
    func appendedValue<R: FixedWidthInteger>(_ value: R) -> Data {
        var value = value
        let d = Data(bytes: &value, count: MemoryLayout<R>.size)
        return self + d
    }
}
