//
//  CrankDataPoint.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - CrankDataPoint

struct CrankDataPoint {
    
    static let DataSize = MemoryLayout<UInt16>.size + MemoryLayout<UInt16>.size
    static let zero = CrankDataPoint()
    
    // MARK: Properties
    
    let revolutions: Int
    let time: Measurement<UnitDuration>
    
    // MARK: init
    
    private init() {
        self.revolutions = 0
        self.time = Measurement<UnitDuration>(value: 0, unit: .seconds)
    }
    
    init(_ data: Data) throws {
        let reader = DataReader(data: data)
        
        revolutions = try reader.read(UInt16.self)
        // Wheel event time is a free-running-count of 1/1024 second units
        // as per CSC Service Documentation.
        time = Measurement<UnitDuration>(value: Double(try reader.read(UInt16.self) / 1024), unit: .seconds)
    }
}
