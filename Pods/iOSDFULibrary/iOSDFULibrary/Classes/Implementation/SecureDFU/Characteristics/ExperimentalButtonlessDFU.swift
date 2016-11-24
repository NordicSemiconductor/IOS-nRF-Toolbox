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

internal enum ExperimentalButtonlessDFUOpCode : UInt8 {
    case enterBootloader      = 0x01
    case responseCode         = 0x20
    
    var code:UInt8 {
        return rawValue
    }
}


internal enum ExperimentalButtonlessDFUResultCode : UInt8 {
    case success            = 0x01
    case opCodeNotSupported = 0x02
    case operationFailed    = 0x04
    
    var description:String {
        switch self {
        case .success:            return "Success"
        case .opCodeNotSupported: return "Operation not supported"
        case .operationFailed :   return "Operation failed"
        }
    }
    
    var code:UInt8 {
        return rawValue
    }
}

internal enum ExperimentalButtonlessDFURequest {
    case enterBootloader
    
    var data : Data {
        switch self {
        case .enterBootloader:
            let byteArray:[UInt8] = [ExperimentalButtonlessDFUOpCode.enterBootloader.code]
            return Data(bytes: UnsafePointer<UInt8>(byteArray), count: byteArray.count)
        }
    }
}

internal struct ExperimentalButtonlessDFUResponse {
    let opCode        : ExperimentalButtonlessDFUOpCode?
    let requestOpCode : ExperimentalButtonlessDFUOpCode?
    let status        : ExperimentalButtonlessDFUResultCode?

    init?(_ data:Data) {
        var opCode        : UInt8 = 0
        var requestOpCode : UInt8 = 0
        var status        : UInt8 = 0
        
        // The correct response is always 3 bytes long: Response Op Code, Request Op Code and Status
        if data.count == 3 {
            (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
            (data as NSData).getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
            (data as NSData).getBytes(&status, range: NSRange(location: 2, length: 1))
        }
        
        self.opCode = ExperimentalButtonlessDFUOpCode(rawValue: opCode)
        self.requestOpCode = ExperimentalButtonlessDFUOpCode(rawValue: requestOpCode)
        self.status = ExperimentalButtonlessDFUResultCode(rawValue: status)
        
        if self.opCode != .responseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }
        
    var description:String {
        return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue))"
    }
}

internal class ExperimentalButtonlessDFU : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "8E400001-F315-4F60-9FB8-838830DAEA50") // the same UUID as the service
    
    static func matches(_ characteristic: CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    private var characteristic: CBCharacteristic
    private var logger: LoggerHelper
    
    private var success: Callback?
    private var report:  ErrorCallback?
    
    internal var valid: Bool {
        return characteristic.properties.isSuperset(of: [CBCharacteristicProperties.write, CBCharacteristicProperties.notify])
    }
    
    // MARK: - Initialization
    init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    
    /**
     Enables notifications for the DFU Control Point characteristics. Reports success or an error
     using callbacks.
     
     - parameter success: method called when notifications were successfully enabled
     - parameter report:  method called in case of an error
     */
    func enableNotifications(onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Save callbacks
        self.success = success
        self.report  = report
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.v("Enabling notifications for \(characteristic.uuid.uuidString)...")
        logger.d("peripheral.setNotifyValue(true, for: \(characteristic.uuid.uuidString))")
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    /**
     Sends given request to the Experimental Buttonless DFU characteristic. Reports success or an error
     using callbacks.
     
     - parameter request: request to be sent
     - parameter success: method called when peripheral reported with status success
     - parameter report:  method called in case of an error
     */
    func send(_ request: ExperimentalButtonlessDFURequest, onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Save callbacks and parameter
        self.success = success
        self.report  = report
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.v("Writing to characteristic \(characteristic.uuid.uuidString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(characteristic.uuid.uuidString), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.e("Enabling notifications failed")
            logger.e(error!)
            report?(.enablingControlPointFailed, "Enabling notifications failed")
        } else {
            logger.v("Notifications enabled for \(characteristic.uuid.uuidString)")
            logger.a("Buttonless DFU notifications enabled")
            success?()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.e("Writing to characteristic failed")
            logger.e(error!)
            report?(.writingCharacteristicFailed, "Writing to characteristic failed")
        } else {
            logger.i("Data written to \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            // This characteristic is never read, the error may only pop up when notification is received
            logger.e("Receiving notification failed")
            logger.e(error!)
            report?(.receivingNotificationFailed, "Receiving notification failed")
            return
        }
        //Otherwise...
        logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x):\(characteristic.value!.hexString)")
        
        // Parse response received
        let dfuResponse = ExperimentalButtonlessDFUResponse(characteristic.value!)
        if let dfuResponse = dfuResponse {
            if dfuResponse.status == .success {
                logger.a("\(dfuResponse.description) received")
                success?()
            } else {
                logger.e("Error \(dfuResponse.status!.code): \(dfuResponse.status!.description)")
                // The returned errod code is incremented by 9000 to match experimental Buttonless DFU remote codes
                report?(DFUError(rawValue: Int(dfuResponse.status!.code) + 9000)!, dfuResponse.status!.description)
            }
        } else {
            logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
            report?(.unsupportedResponse, "Unsupported response received: 0x\(characteristic.value!.hexString)")
        }
    }
}
