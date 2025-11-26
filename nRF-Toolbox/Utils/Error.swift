//
//  Error.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - CriticalError

enum ServiceError: LocalizedError {
    case unknown
    case noMandatoryCharacteristic
    case timeout
    case noData
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error has occurred."
        case .noMandatoryCharacteristic:
            return "Mandatory characteristics are missing."
        case .timeout:
            return "Timeout has occured."
        case .noData:
            return "Ivalid data."
        }
    }
}

enum ServiceWarning: LocalizedError {
    case unknown
    case measurement
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error has occurred"
        case .measurement:
            return "Error occured while reading measurement."
        }
    }
}
