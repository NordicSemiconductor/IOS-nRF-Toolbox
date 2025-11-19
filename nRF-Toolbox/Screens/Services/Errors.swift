//
//  Errors.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 19/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

enum ServiceError: LocalizedError {
    case unknown
    case noMandatoryCharacteristic
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .noMandatoryCharacteristic:
            return "No mandatory characteristic"
        }
    }
}

enum ServiceWarning: LocalizedError {
    case unknown
    case measurement
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .measurement:
            return "Error occured while reading measurement"
        }
    }
}
