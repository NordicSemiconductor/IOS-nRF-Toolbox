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
    
    static let zero = CrankDataPoint()
    
    // MARK: Properties
    
    let revolutions: Int
    let time: Double
    
    // MARK: init
    
    private init() {
        self.revolutions = 0
        self.time = .zero
    }
    
    init?(_ data: Data) {
        let flagsByte = data.littleEndianBytes(as: UInt8.self)
        let flags = BitField<CyclingDataFlag>(RegisterValue(flagsByte))
        
        let revolutionsOffset: Int
        if flags.contains(.wheelData) {
            revolutionsOffset = MemoryLayout<UInt8>.size + MemoryLayout<UInt32>.size + MemoryLayout<UInt16>.size
        } else {
            revolutionsOffset = MemoryLayout<UInt8>.size
        }
        
        guard data.canRead(UInt16.self, atOffset: revolutionsOffset) else {
            return nil
        }
        self.revolutions = data.littleEndianBytes(atOffset: revolutionsOffset, as: UInt16.self)
        let timeOffset = revolutionsOffset + MemoryLayout<UInt16>.size
        guard data.canRead(UInt16.self, atOffset: timeOffset) else {
            return nil
        }
        self.time = Double(data.littleEndianBytes(atOffset: timeOffset, as: UInt16.self))
    }
}
