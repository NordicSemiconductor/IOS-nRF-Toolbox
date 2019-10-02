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
    
    init(with data: Data) {
        let flags: UInt8 = data.read()
        
        heartRate = Flag.isAvailable(bits: flags, flag: .heartRateType)
            ? Int(data.read(fromOffset: 1) as UInt16)
            : Int(data.read(fromOffset: 1) as UInt8)
    }
}
