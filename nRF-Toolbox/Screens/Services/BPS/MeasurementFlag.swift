//
//  MeasurementFlag.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 2/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - MeasurementFlag

enum MeasurementFlag: RegisterValue, Option, CaseIterable {
    case unit
    case timestamp
    case pulseRate
    case userID
    case measurementStatus
}
