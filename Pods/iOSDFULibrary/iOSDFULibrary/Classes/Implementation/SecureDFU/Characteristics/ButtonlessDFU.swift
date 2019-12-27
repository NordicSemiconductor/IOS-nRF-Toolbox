/*
* Copyright (c) 2019, Nordic Semiconductor
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

import CoreBluetooth

internal enum ButtonlessDFUOpCode : UInt8 {
    /// Jump from the main application to Secure DFU bootloader (DFU mode).
    case enterBootloader = 0x01
    /// Set a new advertisement name when jumping to Secure DFU bootloader (DFU mode).
    case setName         = 0x02
    /// The response code.
    case responseCode    = 0x20
    
    var code: UInt8 {
        return rawValue
    }
}


internal enum ButtonlessDFUResultCode : UInt8 {
    /// The operation completed successfully.
    case success            = 0x01
    /// The provided opcode was invalid.
    case opCodeNotSupported = 0x02
    /// The operation failed.
    case operationFailed    = 0x04
    /// The requested advertisement name was invalid (empty or too long).
    /// Only available without bond support.
    case invalidAdvName     = 0x05
    /// The request was rejected due to an ongoing asynchronous operation.
    case busy               = 0x06
    /// The request was rejected because no bond was created.
    case notBonded          = 0x07
    
    var description: String {
        switch self {
        case .success:            return "Success"
        case .opCodeNotSupported: return "Operation not supported"
        case .operationFailed:    return "Operation failed"
        case .invalidAdvName:     return "Invalid advertisment name"
        case .busy:               return "Busy"
        case .notBonded:          return "Device not bonded"
        }
    }
    
    var code: UInt8 {
        return rawValue
    }
}

internal enum ButtonlessDFURequest {
    case enterBootloader
    case set(name : String)
    
    var data : Data {
        switch self {
        case .enterBootloader:
            return Data([ButtonlessDFUOpCode.enterBootloader.code])
        case .set(let name):
            var data = Data([ButtonlessDFUOpCode.setName.code])
            data += UInt8(name.lengthOfBytes(using: String.Encoding.utf8))
            data += name.utf8
            return data
        }
    }
}

internal struct ButtonlessDFUResponse {
    let opCode        : ButtonlessDFUOpCode?
    let requestOpCode : ButtonlessDFUOpCode?
    let status        : ButtonlessDFUResultCode?

    init?(_ data: Data) {
        // The correct response is always 3 bytes long: Response Op Code,
        // Request Op Code and Status.
        let opCode        : UInt8 = data[0]
        let requestOpCode : UInt8 = data[1]
        let status        : UInt8 = data[2]
        
        self.opCode        = ButtonlessDFUOpCode(rawValue: opCode)
        self.requestOpCode = ButtonlessDFUOpCode(rawValue: requestOpCode)
        self.status        = ButtonlessDFUResultCode(rawValue: status)
        
        if self.opCode != .responseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }
        
    var description: String {
        return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue))"
    }
}

internal class ButtonlessDFU : NSObject, CBPeripheralDelegate, DFUCharacteristic {
    
    internal var characteristic: CBCharacteristic
    internal var logger: LoggerHelper
    internal var uuidHelper: DFUUuidHelper!

    private var success: Callback?
    private var report:  ErrorCallback?
    
    internal var valid: Bool {
        return (characteristic.properties.isSuperset(of: [.write, .notify])
            &&  characteristic.uuid.isEqual(uuidHelper.buttonlessExperimentalCharacteristic))
            ||  characteristic.properties.isSuperset(of: [.write, .indicate])
    }
    
    /**
     Returns `true` if the device address is expected to change. In that case,
     the service should scan for another device using `DFUPeripheralSelectorDelegate`.
     */
    internal var newAddressExpected: Bool {
        return characteristic.uuid.isEqual(uuidHelper.buttonlessExperimentalCharacteristic)
            || characteristic.uuid.isEqual(uuidHelper.buttonlessWithoutBonds)
    }
    
    /**
     Returns `true` for a buttonless DFU characteristic that may support setting
     bootloader's name. This feature has been added in SDK 14.0 to Buttonless
     service without bond sharing (the one with bond sharing does not change 
     device address so this feature is not needed). 
     The same characteristic from SDK 13.0 does not support it. Sending this 
     command to that characteristic will end with
     `ButtonlessDFUResultCode.opCodeNotSupported`.
     */
    internal var maySupportSettingName: Bool {
        return characteristic.uuid.isEqual(uuidHelper.buttonlessWithoutBonds)
    }
    
    // MARK: - Initialization
    
    required init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    
    /**
     Enables notifications or indications for the DFU Control Point characteristics,
     depending on the characteristic property. Reports success or an error using
     callbacks.
     
     - parameter success: Method called when notifications were successfully enabled.
     - parameter report:  Method called in case of an error.
     */
    func enable(onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Save callbacks.
        self.success = success
        self.report  = report
        
        // Get the peripheral object.
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        if characteristic.properties.contains(.indicate) {
            logger.v("Enabling indications for \(characteristic.uuid.uuidString)...")
        } else {
            logger.v("Enabling notifications for \(characteristic.uuid.uuidString)...")
        }
        logger.d("peripheral.setNotifyValue(true, for: \(characteristic.uuid.uuidString))")
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    /**
     Sends given request to the Buttonless DFU characteristic.
     Reports success or an error using callbacks.
     
     - parameter request: Request to be sent.
     - parameter success: Method called when peripheral reported with status success.
     - parameter report:  Method called in case of an error.
     */
    func send(_ request: ButtonlessDFURequest,
              onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Save callbacks and parameter.
        self.success = success
        self.report  = report
        
        // Get the peripheral object.
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        let buttonlessUUID = characteristic.uuid.uuidString
        
        logger.v("Writing to characteristic \(buttonlessUUID)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(buttonlessUUID), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if error != nil {
            if characteristic.properties.contains(.indicate) {
                logger.e("Enabling indications failed")
                logger.e(error!)
                report?(.enablingControlPointFailed, "Enabling indications failed")
            } else {
                logger.e("Enabling notifications failed")
                logger.e(error!)
                report?(.enablingControlPointFailed, "Enabling notifications failed")
            }
        } else {
            if characteristic.properties.contains(.indicate) {
                logger.v("Indications enabled for \(characteristic.uuid.uuidString)")
                logger.a("Buttonless DFU indications enabled")
            } else {
                logger.v("Notifications enabled for \(characteristic.uuid.uuidString)")
                logger.a("Buttonless DFU notifications enabled")
            }
            success?()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if error != nil {
            logger.e("Writing to characteristic failed")
            logger.e(error!)
            report?(.writingCharacteristicFailed, "Writing to characteristic failed")
        } else {
            logger.i("Data written to \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // Ignore updates received for other characteristics.
        guard self.characteristic.isEqual(characteristic) else {
            return
        }

        if error != nil {
            // This characteristic is never read, the error may only pop up when notification/indication
            // is received.
            logger.e("Receiving response failed")
            logger.e(error!)
            report?(.receivingNotificationFailed, "Receiving response failed")
        } else {
            if characteristic.properties.contains(.indicate) {
                logger.i("Indication received from \(characteristic.uuid.uuidString), value (0x):\(characteristic.value!.hexString)")
            } else {
                logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x):\(characteristic.value!.hexString)")
            }
            
            // Parse response received.
            let dfuResponse = ButtonlessDFUResponse(characteristic.value!)
            if let dfuResponse = dfuResponse {
                if dfuResponse.status == .success {
                    logger.a("\(dfuResponse.description) received")
                    success?()
                } else {
                    logger.e("Error \(dfuResponse.status!.code): \(dfuResponse.status!.description)")
                    // The returned errod code is incremented by 90 or 9000 to match Buttonless DFU or
                    // Experimental Buttonless DFU remote codes.
                    // See DFUServiceDelegate.swift -> DFUError.
                    let offset = characteristic.uuid.isEqual(uuidHelper.buttonlessExperimentalCharacteristic) ? 9000 : 90
                    report?(DFUError(rawValue: Int(dfuResponse.status!.code) + offset)!, dfuResponse.status!.description)
                }
            } else {
                logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
                report?(.unsupportedResponse, "Unsupported response received: 0x\(characteristic.value!.hexString)")
            }
        }
    }
}
