//
//  HeartRateLocationCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

enum BodySensorLocationCharacteristic: Int, CustomStringConvertible {
    case other, chest, wrist, finger, hand, earLobe, foot
    
    var description: String {
        switch self {
        case .other: return  "Other"
        case .chest: return  "Chest"
        case .wrist: return  "Wrist"
        case .finger: return  "Finger"
        case .hand: return  "Hand"
        case .earLobe: return  "Ear Lobe"
        case .foot: return  "Foot"
        }
    }
    
    init?(with data: Data) {
        let value: UInt8 = data.read()
        self.init(rawValue: Int(value))
    }
}
