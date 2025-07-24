//
//  RSCMeasurement.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

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

    let flags: BitField<RunningSpeedAndCadence.RSCFeature>
    let instantaneousSpeed: Measurement<UnitSpeed>
    let instantaneousCadence: Int
    let instantaneousStrideLength: Measurement<UnitLength>?
    let totalDistance: Measurement<UnitLength>?
    
    var isRunning: Bool {
        flags.contains(.walkingOrRunningStatus)
    }

    init(data: Data, flags: BitField<RunningSpeedAndCadence.RSCFeature>, instantaneousSpeed: Measurement<UnitSpeed>, instantaneousCadence: Int, instantaneousStrideLength: Measurement<UnitLength>?, totalDistance: Measurement<UnitLength>?) {
        self.data = data
        self.flags = flags
        self.instantaneousSpeed = instantaneousSpeed
        self.instantaneousCadence = instantaneousCadence
        self.instantaneousStrideLength = instantaneousStrideLength
        self.totalDistance = totalDistance
    }
    
    init(rawData: RunningSpeedAndCadence.RSCSMeasurement) {
        self.data = rawData.data
        self.flags = rawData.flags
        self.instantaneousSpeed = Measurement(value: Double(rawData.instantaneousSpeed) / 256.0, unit: .metersPerSecond)
        self.instantaneousCadence = Int(rawData.instantaneousCadence)
        
        self.instantaneousStrideLength = flags.contains(.instantaneousStrideLengthMeasurement)
            ? Measurement(value: Double(rawData.instantaneousStrideLength!), unit: .centimeters)
            : nil
        
        self.totalDistance = flags.contains(.totalDistanceMeasurement)
            ? Measurement(value: Double(rawData.totalDistance!), unit: .meters)
            : nil
    }
}
