//
//  CBUUID+IDs.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBUUID {
    struct Profile {
        static let bloodGlucoseMonitor = CBUUID(string: "00001808-0000-1000-8000-00805F9B34FB")
        static let cyclingSpeedCadenceSensor = CBUUID(string: "00001816-0000-1000-8000-00805F9B34FB")
        static let runningSpeedCadenceSensor = CBUUID(string: "00001814-0000-1000-8000-00805F9B34FB")
    }
    
    struct Service {
        static let battery = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")
        static let bloodGlucoseMonitor = CBUUID(string: "00001808-0000-1000-8000-00805F9B34FB")
        static let cyclingSpeedCadenceSensor = CBUUID(string: "00001816-0000-1000-8000-00805F9B34FB")
        static let runningSpeedCadenceSensor = CBUUID(string: "00001814-0000-1000-8000-00805F9B34FB")
    }
    
    struct Characteristics {
        struct Battery {
            static let batteryLevel = CBUUID(string: "00002A19-0000-1000-8000-00805F9B34FB")
        }
        
        struct BloodGlucoseMonitor {
            static let glucoseMeasurement = CBUUID(string: "00002A18-0000-1000-8000-00805F9B34FB")
            static let glucoseMeasurementContext = CBUUID(string: "00002A34-0000-1000-8000-00805F9B34FB")
            static let recordAccessControlPoint = CBUUID(string: "00002A52-0000-1000-8000-00805F9B34FB")
        }
        
        struct CyclingSesnor {
            static let measurement = CBUUID(string: "00002A5B-0000-1000-8000-00805F9B34FB")
        }
        
        struct Running {
            static let measurement = CBUUID(string: "00002A53-0000-1000-8000-00805F9B34FB")
        }
    }
}
