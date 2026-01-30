//
//  CGMSStatusOctet.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 08/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CGMSStatusOctet

enum CGMSSensorStatusOctet: RegisterValue, Option, CustomStringConvertible {
    case sessionStopped,
         deviceBatteryLow,
         sensorTypeIncorrectForDevice,
         sensorMalfunction,
         deviceSpecificAlert,
         generalFault
    
    public var description: String {
        switch self {
        case .sessionStopped:
            return "Session stopped"
        case .deviceBatteryLow:
            return "Device battery low"
        case .sensorTypeIncorrectForDevice:
            return "Sensor type incorrect for device"
        case .sensorMalfunction:
            return "Sensor malfunction"
        case .deviceSpecificAlert:
            return "Device specific alert"
        case .generalFault:
            return "General fault"
        }
    }
}
