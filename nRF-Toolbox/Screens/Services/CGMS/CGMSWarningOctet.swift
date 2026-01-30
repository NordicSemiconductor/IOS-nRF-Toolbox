//
//  CGMSWarningOctet.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 08/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CGMSWarningOctet

enum CGMSWarningOctet: RegisterValue, Option, CustomStringConvertible {
    case resultLowerThanThePatientLowLevel,
         resulthigherThanThePatientHightLevel,
         resultLowerThanTheHypoLevel,
         resultHigherThanTheHyperLevel,
         rateOfDecreaseExceeded,
         rateOfIncreaseExceeded,
         resultLowerThanTheDeviceCanProcess,
         resultHigherThanTheDeviceCanProcess
    
    public var description: String {
        switch self {
        case .resultLowerThanThePatientLowLevel:
            return "Result lower than the patient low level"
        case .resulthigherThanThePatientHightLevel:
            return "Result higher than the patient high level"
        case .resultLowerThanTheHypoLevel:
            return "Result lower than the hypo level"
        case .resultHigherThanTheHyperLevel:
            return "Result higher than the hyper level"
        case .rateOfDecreaseExceeded:
            return "Rate of decrease exceeded"
        case .rateOfIncreaseExceeded:
            return "Rate of increase exceeded"
        case .resultLowerThanTheDeviceCanProcess:
            return "Result lower thant the device can process"
        case .resultHigherThanTheDeviceCanProcess:
            return "Result higher thant the device can process"
        }
    }
}
