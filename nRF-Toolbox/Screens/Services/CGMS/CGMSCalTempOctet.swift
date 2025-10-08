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

enum CGMSCalTempOctet: RegisterValue, Option {
    case timeSyncRequired,
         calibrationNotAllowed,
         calibrationRecommended,
         calibrationRequired,
         sensorTempTooHigh,
         sensorTempTooLow
}
