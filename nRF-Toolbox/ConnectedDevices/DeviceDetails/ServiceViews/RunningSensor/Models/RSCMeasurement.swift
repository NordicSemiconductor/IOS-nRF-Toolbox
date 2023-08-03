//
//  RSCMeasurement.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock_Collection

struct RSCMeasurement: CustomDebugStringConvertible {
    var debugDescription: String {
        let mirror = Mirror(reflecting: self)
        var str: String = ""
        for e in mirror.children {
            str += "\(e.label ?? "no-label"): \(e.value) "
        }
        
        return str
    }
    
    let data: Data

    let flags: RunningSpeedAndCadence.RSCMeasurementFlags
    let instantaneousSpeed: Measurement<UnitSpeed>
    let instantaneousCadence: Int
    let instantaneousStrideLength: Measurement<UnitLength>?
    let totalDistance: Measurement<UnitLength>?

    init(data: Data, flags: RunningSpeedAndCadence.RSCMeasurementFlags, instantaneousSpeed: Measurement<UnitSpeed>, instantaneousCadence: Int, instantaneousStrideLength: Measurement<UnitLength>?, totalDistance: Measurement<UnitLength>?) {
        self.data = data
        self.flags = flags
        self.instantaneousSpeed = instantaneousSpeed
        self.instantaneousCadence = instantaneousCadence
        self.instantaneousStrideLength = instantaneousStrideLength
        self.totalDistance = totalDistance
    }

    init(data: Data) throws {
        self.data = data

        self.flags = RunningSpeedAndCadence.RSCMeasurementFlags(rawValue: UInt8(data[0]))
        let spead: UInt16 = try data.read(fromOffset: 1)
        self.instantaneousSpeed = Measurement(value: Double(spead) / 256.0, unit: .metersPerSecond)

        self.instantaneousCadence = Int(data[3])

        var offset: Int = 4

        if flags.contains(.instantaneousStrideLengthPresent) {
            let strideLength: UInt16 = try data.read(fromOffset: offset)
            self.instantaneousStrideLength = Measurement(value: Double(strideLength) / 100.0, unit: .meters)
            offset += 2
        } else {
            self.instantaneousStrideLength = nil
        }

        if flags.contains(.totalDistancePresent) {
            let totalDistance: UInt32 = try data.read(fromOffset: offset)
            self.totalDistance = Measurement(value: Double(totalDistance) / 10.0, unit: .meters)
        } else {
            self.totalDistance = nil
        }
    }
}
