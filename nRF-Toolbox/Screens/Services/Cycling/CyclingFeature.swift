//
//  CyclingFeature.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CyclingFlag

enum CyclingFlag: RegisterValue, Option, CustomStringConvertible {
    case wheelRevolution, crankRevolution, multipleSensorLocations
    
    var description: String {
        switch self {
        case .wheelRevolution:
            return "Wheel Revolution"
        case .crankRevolution:
            return "Crank Revolution"
        case .multipleSensorLocations:
            return "Multiple Sensor Locations"
        }
    }
}
