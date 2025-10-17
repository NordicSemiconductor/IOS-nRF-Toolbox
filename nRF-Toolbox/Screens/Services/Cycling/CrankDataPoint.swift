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
    let time: Double
    
    // MARK: init
    
    private init() {
        self.revolutions = 0
        self.time = .zero
    }
    
    init(_ data: Data) throws {
        let reader = DataReader(data: data)
        
        revolutions = try reader.readInt(UInt16.self)
        time = Double(try reader.readInt(UInt16.self))
    }
}
