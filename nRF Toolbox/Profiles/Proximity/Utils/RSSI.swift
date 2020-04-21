//
//  RSSI.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 21.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIColor

enum RSSI: Int {
    case outOfRange = 127
    case practicalWorst = -100
    case bad
    case ok
    case good

    var color: UIColor {
        switch self {
        case .outOfRange: return UIColor.nordicGrey4
        case .practicalWorst, .bad: return UIColor.nordicRed
        case .ok: return UIColor.nordicYello
        case .good: return UIColor.nordicBlue
        }
    }

    static func from(RSSI: Int) -> RSSI {
        guard RSSI <= 4 else { return .outOfRange }

        switch RSSI {
        case (-60)...(-20): return .good
        case (-89)...(-20): return .ok
        default:
            return .bad
        }
    }
    
    static func percent(from RSSI: Int) -> Double {
        let best = -60
        let worst = -80
        
        
        if RSSI >= best {
            return 1
        }
        
        if RSSI <= worst {
            return 0
        }
        
        return 1 - Double(RSSI + -best) / Double(worst - best)
    }
}
