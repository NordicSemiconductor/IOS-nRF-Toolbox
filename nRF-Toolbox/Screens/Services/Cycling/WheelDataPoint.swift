//
//  WheelDataPoint.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - WheelDataPoint

struct WheelDataPoint {
    
    static let zero = WheelDataPoint()
    
    // MARK: Properties
    
    let revolutions: Int
    let time: Measurement<UnitDuration>
    
    // MARK: init
    
    private init() {
        self.revolutions = 0
        self.time = Measurement<UnitDuration>(value: 0, unit: .seconds)
    }
    
    init?(_ data: Data) {
        // byte 0 is assumed to be Data Flags
        let revolutionsOffset = MemoryLayout<UInt8>.size
        guard data.canRead(UInt32.self, atOffset: revolutionsOffset) else {
            return nil
        }
        self.revolutions = data.littleEndianBytes(atOffset: revolutionsOffset, as: UInt32.self)
        let timeOffset = revolutionsOffset + MemoryLayout<UInt32>.size
        guard data.canRead(UInt16.self, atOffset: timeOffset) else {
            return nil
        }
        // Wheel event time is a free-running-count of 1/1024 second units
        // as per CSC Service Documentation.
        self.time = Measurement<UnitDuration>(value: Double(data.littleEndianBytes(atOffset: timeOffset, as: UInt16.self) / 1024), unit: .seconds)
    }
}
