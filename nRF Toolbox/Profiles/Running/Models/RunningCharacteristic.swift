//
//  RunningCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 25/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let strideLength: Flag = 0x01
    static let totalDistance: Flag = 0x02
    static let isRunning: Flag = 0x04
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
        
        let bitFlags: UInt8 = data.read(fromOffset: 0)
        
        isRunning = Flag.isAvailable(bits: bitFlags, flag: .isRunning)
        
        instantaneousStrideLength = Flag.isAvailable(bits: bitFlags, flag: .strideLength) ? {
                let strideLengthValue: UInt16 = data.read(fromOffset: 4)
                return Measurement(value: Double(strideLengthValue), unit: .centimeters)
            }() : nil
        
        totalDistance = Flag.isAvailable(bits: bitFlags, flag: .totalDistance) ? {
                let totalDistanceValue: UInt32 = data.read(fromOffset: 6)
                return Measurement(value: Double(totalDistanceValue), unit: .decameters)
            }() : nil
    }
}
