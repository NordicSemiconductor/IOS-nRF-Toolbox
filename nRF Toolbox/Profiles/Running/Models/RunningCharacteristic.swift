//
//  RunningCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 25/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

func &(lhs: UInt8, rhs: UInt8) -> Bool {
    return (lhs & rhs) > 0
}

class PaceMeasurementFormatter: MeasurementFormatter {
    func paceString(from measurement: Measurement<UnitSpeed>) -> String {
        let distanceUnit: UnitLength = locale.usesMetricSystem ? .kilometers : .miles
        let metersInUnit = Measurement<UnitLength>(value: 1, unit: distanceUnit).converted(to: .meters).value
        
        let mpsValue = measurement.converted(to: .metersPerSecond).value
        let paceValue = 1 / (mpsValue / metersInUnit)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        let timeStr = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: paceValue))
        
        return "\(timeStr) min/\(distanceUnit.symbol)"
    }
}

struct RunningCharacteristic {
    
    let instantaneousSpeed: Measurement<UnitSpeed>
    let instantaneousCadence: Int
    let instantaneousStrideLength: Measurement<UnitLength>?
    let totalDistance: Measurement<UnitLength>?
    let isRunning: Bool
     
    init(data: Data) {
        let instantaneousSpeedValue = Double(data.read(fromOffset: 1) as UInt16) / 256
        instantaneousSpeed = Measurement(value: instantaneousSpeedValue, unit: .metersPerSecond)
        instantaneousCadence = Int(data.read(fromOffset: 3) as UInt8)
        
        let flags: UInt8 = data.read(fromOffset: 0)
        
        isRunning = flags & 0x04
        
        instantaneousStrideLength = flags & 0x01 ? {
                let strideLengthValue: UInt16 = data.read(fromOffset: 4)
                return Measurement(value: Double(strideLengthValue), unit: .centimeters)
            }() : nil
        
        totalDistance = flags & 0x02 ? {
                let totalDistanceValue: UInt32 = data.read(fromOffset: 6)
                return Measurement(value: Double(totalDistanceValue), unit: .decameters)
            }() : nil
    }
}
