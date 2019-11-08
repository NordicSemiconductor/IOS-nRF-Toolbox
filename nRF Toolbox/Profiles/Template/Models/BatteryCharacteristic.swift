//
//  BatteryCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct BatteryCharacteristic {
    let batteryLevel: Int
    
    init(with data: Data) {
        let batteryLevelValue: Int8 = data.read()
        batteryLevel = Int(batteryLevelValue)
    }
}
