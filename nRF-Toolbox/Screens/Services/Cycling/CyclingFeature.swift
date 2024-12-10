//
//  CyclingFeature.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

enum CyclingFlag: RegisterValue, Option {
    case wheelRevolution = 0
    case crankRevolution = 1
    case multipleSensorLocations = 2
}

struct CyclingFeatures {
    
    private var flags: BitField<CyclingFlag>
    
    init(flags: RegisterValue) {
        self.flags = BitField(flags)
    }
    
    subscript(flag: CyclingFlag) -> Bool {
        get {
            flags.contains(flag)
        }
        set {
            guard flags.contains(flag) != newValue else { return }
            flags.flip(flag)
        }
    }
}
