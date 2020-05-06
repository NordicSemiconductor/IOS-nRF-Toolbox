/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import Foundation
import CoreBluetooth

extension CBUUID {

    convenience init(hex: Int) {
        self.init(string: String(hex, radix: 16).uppercased())
    }

    struct Profile {
        static let bloodGlucoseMonitor = CBUUID(string: "00001808-0000-1000-8000-00805F9B34FB")
        static let cyclingSpeedCadenceSensor = CBUUID(string: "00001816-0000-1000-8000-00805F9B34FB")
        static let runningSpeedCadenceSensor = CBUUID(string: "00001814-0000-1000-8000-00805F9B34FB")
        static let bloodPressureMonitor = CBUUID(string: "00001810-0000-1000-8000-00805F9B34FB")
        static let healthTemperature = CBUUID(string: "00001809-0000-1000-8000-00805F9B34FB")
        static let heartRateSensor = CBUUID(string: "0000180D-0000-1000-8000-00805F9B34FB")
    }
    
    struct Service {
        static let battery = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")
        static let bloodGlucoseMonitor = CBUUID(string: "00001808-0000-1000-8000-00805F9B34FB")
        static let cyclingSpeedCadenceSensor = CBUUID(string: "00001816-0000-1000-8000-00805F9B34FB")
        static let runningSpeedCadenceSensor = CBUUID(string: "00001814-0000-1000-8000-00805F9B34FB")
        static let bloodPressureMonitor = CBUUID(string: "00001810-0000-1000-8000-00805F9B34FB")
        static let healthTemperature = CBUUID(string: "00001809-0000-1000-8000-00805F9B34FB")
        static let heartRateSensor = CBUUID(string: "0000180D-0000-1000-8000-00805F9B34FB")
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
        
        struct BloodPressure {
            static let measurement = CBUUID(string: "00002A35-0000-1000-8000-00805F9B34FB")
            static let intermediateCuff = CBUUID(string: "00002A36-0000-1000-8000-00805F9B34FB")
        }
        
        struct HealthTemperature {
            static let measurement = CBUUID(string: "00002A1C-0000-1000-8000-00805F9B34FB")
        }
        
        struct HeartRate {
            static let measurement = CBUUID(string: "00002A37-0000-1000-8000-00805F9B34FB")
            static let location = CBUUID(string: "00002A38-0000-1000-8000-00805F9B34FB")
        }
    }
}
