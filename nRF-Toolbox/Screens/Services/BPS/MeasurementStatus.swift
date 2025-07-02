//
//  MeasurementStatus.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 2/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - MeasurementStatus

enum MeasurementStatus: RegisterValue, Option, CustomStringConvertible {
    case bodyMovement
    case cuffFitLoose
    case irregularPulse
    case pulseRateAboveUpperLimit
    case pulseRateLessThanLimitOrReserved // If bit is zero, it means "Pulse rate is less than lower limit"
    case improperPosition
    
    var description: String {
        switch self {
        case .bodyMovement:
            return "Body movement"
        case .cuffFitLoose:
            return "Cuff fit too loose"
        case .irregularPulse:
            return "Irregular pulse"
        case .pulseRateAboveUpperLimit:
            return "Pulse rate exceeds upper limit"
        case .pulseRateLessThanLimitOrReserved:
            return "Reserved for future use"
        case .improperPosition:
            return "Improper measurement position"
        }
    }
}
