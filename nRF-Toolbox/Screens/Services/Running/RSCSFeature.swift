//
//  RSCFeature.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 29/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: RSCSFeatureFlags
    
public enum RSCSFeature: RegisterValue, Option, CustomStringConvertible, CaseIterable {
    case instantaneousStrideLengthMeasurement
    case totalDistanceMeasurement
    case walkingOrRunningStatus
    case sensorCalibrationProcedure
    case multipleSensorLocation
    
    public var description: String {
        switch self {
        case .instantaneousStrideLengthMeasurement:
            return "Instantaneous Stride Length Measurement"
        case .totalDistanceMeasurement:
            return "Total Distance Measurement"
        case .walkingOrRunningStatus:
            return "Walking or Running Status"
        case .sensorCalibrationProcedure:
            return "Sensor Calibration Procedure"
        case .multipleSensorLocation:
            return "Multiple Sensor Location"
        }
    }
}
