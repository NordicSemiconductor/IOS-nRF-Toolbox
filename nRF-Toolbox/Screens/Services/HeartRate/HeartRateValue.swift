//
//  HeartRateValue.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 1/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - HeartRateValue

struct HeartRateValue {
    
    // MARK: Properties
    
    let measurement: HeartRateMeasurement
    let date: Date
    
    // MARK: init
    
    init(with data: Data) throws {
        self.measurement = try HeartRateMeasurement(data)
        self.date = .now
    }
}
