//
//  CGMSCalTempOctet.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 08/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CGMSCalTempOctet

enum CGMSCalTempOctet: RegisterValue, Option, CustomStringConvertible {
    case timeSyncRequired,
         calibrationNotAllowed,
         calibrationRecommended,
         calibrationRequired,
         sensorTempTooHigh,
         sensorTempTooLow
    
    public var description: String {
        switch self {
        case .timeSyncRequired:
            return "Time sync required"
        case .calibrationNotAllowed:
            return "Calibration not allowed"
        case .calibrationRecommended:
            return "Calibration recommended"
        case .calibrationRequired:
            return "Calibration required"
        case .sensorTempTooHigh:
            return "Sensor temp too high"
        case .sensorTempTooLow:
            return "Sensor temp too low"
        }
    }
}
