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

internal typealias VersionCallback = (_ major: UInt8, _ minor: UInt8) -> Void

@objc internal class DFUVersion : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "00001534-1212-EFDE-1523-785FEABCD123")
    
    static func matches(_ characteristic: CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    private var characteristic: CBCharacteristic
    private var logger: LoggerHelper
    
    private var success: VersionCallback?
    private var report: ErrorCallback?
    
    internal var valid: Bool {
        return characteristic.properties.contains(.read)
    }
    
    // MARK: - Initialization
    
    init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
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
    func readVersion(onSuccess success: VersionCallback?, onError report: ErrorCallback?) {
        // Save callbacks
        self.success = success
        self.report = report
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.v("Reading DFU Version number...")
        logger.d("peripheral.readValue(\(characteristic.uuid.uuidString))")
        peripheral.readValue(for: characteristic)
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Ignore updates received for other characteristics
        guard characteristic.uuid.isEqual(DFUVersion.UUID) else {
            return
        }
        
        if error != nil {
            logger.e("Reading DFU Version characteristic failed")
            logger.e(error!)
            report?(.readingVersionFailed, "Reading DFU Version characteristic failed")
        } else {
            let data = characteristic.value
            logger.i("Read Response received from \(characteristic.uuid.uuidString), value\(data != nil && data!.count > 0 ? " (0x): " + data!.hexString : ": 0 bytes")")
            
            // Validate data length
            if data == nil || data!.count != 2 {
                logger.w("Invalid value: 2 bytes expected")
                report?(.readingVersionFailed, "Unsupported DFU Version: \(data != nil && data!.count > 0 ? "0x" + data!.hexString : "no value")")
                return
            }
            
            // Read major and minor
            let minor: UInt8 = data![0]
            let major: UInt8 = data![1]
            
            logger.a("Version number read: \(major).\(minor)")
            success?(major, minor)
        }
    }
}
