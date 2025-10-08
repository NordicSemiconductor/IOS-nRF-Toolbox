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

enum CGMSSensorStatusOctet: RegisterValue, Option {
    case sessionStopped,
         deviceBatteryLow,
         sensorTypeIncorrectForDevice,
         sensorMalfunction,
         deviceSpecificAlert,
         generalFault
}
