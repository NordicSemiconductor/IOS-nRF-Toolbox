//
//  BloodPreasureCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let unitFlag: Flag = 0x01
    static let timeStamp: Flag = 0x02
    static let pulseRate: Flag = 0x04
}

struct BloodPressureCharacteristic {
    
    let systolicPressure: Measurement<UnitPressure>
    let diastolicPressure: Measurement<UnitPressure>
    let meanArterialPressure: Measurement<UnitPressure>
    let date: Date?
    let pulseRate: Int?
    
    init(data: Data) {
        let flags: UInt8 = data.read()
        let unit: UnitPressure = Flag.isAvailable(bits: flags, flag: .unitFlag) ? .millimetersOfMercury : .kilopascals
        
        let systolicValue: Float32 = data.readSFloat(from: 1)
        let diastolicValue: Float32 = data.readSFloat(from: 3)
        let meanArterialValue: Float32 = data.readSFloat(from: 5)
        
        systolicPressure = Measurement<UnitPressure>(value: Double(systolicValue), unit: unit)
        diastolicPressure = Measurement<UnitPressure>(value: Double(diastolicValue), unit: unit)
        meanArterialPressure = Measurement<UnitPressure>(value: Double(meanArterialValue), unit: unit)
        
        var offset = 7
        date = Flag.isAvailable(bits: flags, flag: .timeStamp) ? {
                defer { offset += 7 }
                return data.readDate(from: offset)
            }() : nil
        
        pulseRate = Flag.isAvailable(bits: flags, flag: .pulseRate) ? {
                let pulseValue = data.readSFloat(from: offset)
                return Int(pulseValue)
            }() : nil
    }
}
