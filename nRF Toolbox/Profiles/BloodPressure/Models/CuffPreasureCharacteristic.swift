//
//  CuffPreasureCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let unitFlag: Flag = 0x01
}

struct CuffPreasureCharacteristic {
    let cuffPreasure: Measurement<UnitPressure>
    
    init(data: Data) {
        let flags: UInt8 = data.read()
        let unit: UnitPressure = Flag.isAvailable(bits: flags, flag: .unitFlag) ? .millimetersOfMercury : .kilopascals
        
        let cuffPressureValue: Float32 = data.readSFloat(from: 1)
        cuffPreasure = Measurement<UnitPressure>(value: Double(cuffPressureValue), unit: unit)
    }
    
}
