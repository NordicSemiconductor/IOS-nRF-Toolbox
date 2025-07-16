//
//  Battery.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 31/10/2023.
//  Created by Dinesh Harjani on 16/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Bluetooth_Numbers_Database
import CoreBluetoothMock

public struct Battery {
    
    public struct Level: ExpressibleByIntegerLiteral {
        public typealias IntegerLiteralType = UInt
        public init(integerLiteral value: UInt) {
            self.level = value
        }
        
        public let level: UInt
        
        public init(level: UInt) {
            self.level = level
        }
        
        public init(data: Data) {
            let level: UInt8 = data[0]
            self.level = UInt(level)
        }
    }
    
    public struct LevelStatus { }
    public struct EstimatedServiceDate { }
    public struct CriticalStatus { }
    public struct EnergyStatus { }
    public struct TimeStatus { }
    public struct HealthStatus { }
    public struct HealthInformation { }
    public struct Information { }
}
