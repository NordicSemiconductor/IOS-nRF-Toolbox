//
//  HeartRateMeasurementCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let heartRateType: Flag = 0x01
}

struct HeartRateMeasurementCharacteristic {
    let heartRate: Int
    let date: Date
    
    init(with data: Data, date: Date) {
        self.date = date

        let flags: UInt8 = data.read()
        
        heartRate = Flag.isAvailable(bits: flags, flag: .heartRateType)
            ? Int(data.read(fromOffset: 1) as UInt16)
            : Int(data.read(fromOffset: 1) as UInt8)
    }

    #if DEBUG
    init(value: Double) {
        self.heartRate = Int(value)
        self.date = Date()
    }
    #endif
}
