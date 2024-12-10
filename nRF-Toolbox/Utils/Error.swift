//
//  Error.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - CriticalError

enum CriticalError: Error {
    case noMandatoryCharacteristics
    case timeout
    case noData
    case unknown
}
