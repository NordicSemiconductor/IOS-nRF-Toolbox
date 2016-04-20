/*
* Copyright (c) 2016, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
* documentation and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
* software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import CoreBluetooth

internal typealias VersionCallback = (major:Int, minor:Int) -> Void

@objc internal class DFUVersion : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "00001534-1212-EFDE-1523-785FEABCD123")
    
    static func matches(characteristic:CBCharacteristic) -> Bool {
        return characteristic.UUID.isEqual(UUID)
    }
    
    private var characteristic:CBCharacteristic
    private var logger:LoggerHelper
    
    private var success:VersionCallback?
    private var report:ErrorCallback?
    
    var valid:Bool {
        return characteristic.properties.contains(CBCharacteristicProperties.Read)
    }
    
    // MARK: - Initialization
    
    init(_ characteristic:CBCharacteristic, _ logger:LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    
    /**
    Reads the value of the DFU Version characteristic.
    The value, or an error, will be reported as a callback.
    
    - parameter callback: method called when version is read and is supported
    - parameter error:    method called on error of if version is not supported
    */
    func readVersion(onSuccess success:VersionCallback?, onError report:ErrorCallback?) {
        // Save callbacks
        self.success = success
        self.report = report
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.v("Reading DFU Version number...")
        logger.d("peripheral.readValueForCharacteristic(\(DFUVersion.UUID.UUIDString))")
        peripheral.readValueForCharacteristic(characteristic)
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            logger.e("Reading DFU Version characteristic failed")
            logger.e(error!)
            report?(error:DFUError.ReadingVersionFailed, withMessage:"Reading DFU Version characteristic failed")
        } else {
            let data = characteristic.value
            logger.i("Read Response received from \(DFUVersion.UUID.UUIDString), \("value (0x):" + (data?.hexString ?? "no value"))")
            
            // Validate data length
            if data == nil || data!.length != 2 {
                logger.w("Invalid value: 2 bytes expected")
                report?(error:DFUError.ReadingVersionFailed, withMessage:"Unsupported DFU Version value: \(data != nil ? "0x" + data!.hexString : "nil"))")
                return
            }
            
            // Read major and minor
            var minor:Int = 0
            var major:Int = 0
            data?.getBytes(&minor, range: NSRange(location: 0, length: 1))
            data?.getBytes(&major, range: NSRange(location: 1, length: 1))
            
            logger.a("Version number read: \(major).\(minor)")
            success?(major: major, minor: minor)
        }
    }
}
