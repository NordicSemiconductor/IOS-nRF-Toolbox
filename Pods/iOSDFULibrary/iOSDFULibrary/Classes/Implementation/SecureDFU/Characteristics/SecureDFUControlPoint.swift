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

internal enum SecureDFUOpCode : UInt8 {
    case createObject         = 0x01
    case setPRNValue          = 0x02
    case calculateChecksum    = 0x03
    case execute              = 0x04
    case readObjectInfo       = 0x06
    case responseCode         = 0x60

    var code: UInt8 {
        return rawValue
    }
}

internal enum SecureDFUExtendedErrorCode : UInt8 {
    case noError              = 0x00
    case wrongCommandFormat   = 0x02
    case unknownCommand       = 0x03
    case initCommandInvalid   = 0x04
    case fwVersionFailure     = 0x05
    case hwVersionFailure     = 0x06
    case sdVersionFailure     = 0x07
    case signatureMissing     = 0x08
    case wrongHashType        = 0x09
    case hashFailed           = 0x0A
    case wrongSignatureType   = 0x0B
    case verificationFailed   = 0x0C
    case insufficientSpace    = 0x0D
    
    var code: UInt8 {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .noError:              return "No error"
        case .wrongCommandFormat:   return "Wrong command format"
        case .unknownCommand:       return "Unknown command"
        case .initCommandInvalid:   return "Init command was invalid"
        case .fwVersionFailure:     return "FW version check failed"
        case .hwVersionFailure:     return "HW version check failed"
        case .sdVersionFailure:     return "SD version check failed"
        case .signatureMissing:     return "Signature missing"
        case .wrongHashType:        return "Invalid hash type"
        case .hashFailed:           return "Hashing failed"
        case .wrongSignatureType:   return "Invalid signature type"
        case .verificationFailed:   return "Verification failed"
        case .insufficientSpace:    return "Insufficient space for upgrade"
        }
    }
    
}

internal enum SecureDFUProcedureType : UInt8 {
    case command = 0x01
    case data    = 0x02
    
    var description: String{
        switch self{
            case .command:  return "Command"
            case .data:     return "Data"
        }
    }
}

internal enum SecureDFURequest {
    case createCommandObject(withSize : UInt32)
    case createDataObject(withSize : UInt32)
    case readCommandObjectInfo
    case readDataObjectInfo
    case setPacketReceiptNotification(value : UInt16)
    case calculateChecksumCommand
    case executeCommand

    var data : Data {
        switch self {
        case .createDataObject(let aSize):
            //Split to UInt8
            let byteArray = stride(from: 24, through: 0, by: -8).map {
                UInt8(truncatingBitPattern: aSize >> UInt32($0))
            }
            //Size is converted to Little Endian (0123 -> 3210)
            let bytes:[UInt8] = [SecureDFUOpCode.createObject.code, SecureDFUProcedureType.data.rawValue, byteArray[3], byteArray[2], byteArray[1], byteArray[0]]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .createCommandObject(let aSize):
            //Split to UInt8
            let byteArray = stride(from: 24, through: 0, by: -8).map {
                UInt8(truncatingBitPattern: aSize >> UInt32($0))
            }
            //Size is converted to Little Endian (0123 -> 3210)
            let bytes:[UInt8] = [SecureDFUOpCode.createObject.code, SecureDFUProcedureType.command.rawValue, byteArray[3], byteArray[2], byteArray[1], byteArray[0]]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .readCommandObjectInfo:
            let bytes:[UInt8] = [SecureDFUOpCode.readObjectInfo.code, SecureDFUProcedureType.command.rawValue]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .readDataObjectInfo:
            let bytes:[UInt8] = [SecureDFUOpCode.readObjectInfo.code, SecureDFUProcedureType.data.rawValue]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .setPacketReceiptNotification(let aSize):
            let byteArary:[UInt8] = [UInt8(aSize>>8), UInt8(aSize & 0x00FF)]
            let bytes:[UInt8] = [SecureDFUOpCode.setPRNValue.code, byteArary[1], byteArary[0]]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .calculateChecksumCommand:
            let byteArray:[UInt8] = [SecureDFUOpCode.calculateChecksum.code]
            return Data(bytes: UnsafePointer<UInt8>(byteArray), count: byteArray.count)
        case .executeCommand:
            let byteArray:[UInt8] = [SecureDFUOpCode.execute.code]
            return Data(bytes: UnsafePointer<UInt8>(byteArray), count: byteArray.count)
        }
    }

    var description : String {
        switch self {
        case .createCommandObject(let size):  return "Create Command Object (Op Code = 1, Type = 1, Size: \(size)b)"
        case .createDataObject(let size):     return "Create Data Object (Op Code = 1, Type = 2, Size: \(size)b)"
        case .readCommandObjectInfo:        return "Read Command Object Info (Op Code = 6, Type = 1)"
        case .readDataObjectInfo:           return "Read Data Object Info (Op Code = 6, Type = 2)"
        case .setPacketReceiptNotification(let number):
                                              return "Packet Receipt Notif Req (Op Code = 2, Value = \(number))"
        case .calculateChecksumCommand:     return "Calculate Checksum (Op Code = 3)"
        case .executeCommand:               return "Execute Object (Op Code = 4)"
        }
    }
}

internal enum SecureDFUResultCode : UInt8 {
    case invalidCode           = 0x0
    case success               = 0x01
    case opCodeNotSupported    = 0x02
    case invalidParameter      = 0x03
    case insufficientResources = 0x04
    case invalidObject         = 0x05
    case signatureMismatch     = 0x06
    case unsupportedType       = 0x07
    case operationNotpermitted = 0x08
    case operationFailed       = 0x0A
    case extendedError         = 0x0B
    
    var description: String {
        switch self {
            case .invalidCode:           return "Invalid code"
            case .success:               return "Success"
            case .opCodeNotSupported:    return "Operation not supported"
            case .invalidParameter:      return "Invalid parameter"
            case .insufficientResources: return "Insufficient resources"
            case .invalidObject:         return "Invalid object"
            case .signatureMismatch:     return "Signature mismatch"
            case .operationNotpermitted: return "Operation not permitted"
            case .unsupportedType:       return "Unsupported type"
            case .operationFailed:       return "Operation failed"
            case .extendedError:         return "Extended error"
        }
    }
    
    var code: UInt8 {
        return rawValue
    }
}

internal typealias SecureDFUResponseCallback = (_ response : SecureDFUResponse?) -> Void

internal struct SecureDFUResponse {
    let opCode        : SecureDFUOpCode?
    let requestOpCode : SecureDFUOpCode?
    let status        : SecureDFUResultCode?
    let maxSize       : UInt32?
    let offset        : UInt32?
    let crc           : UInt32?
    let error         : SecureDFUExtendedErrorCode?
    
    init?(_ data: Data) {
        var opCode        : UInt8 = 0
        var requestOpCode : UInt8 = 0
        var status        : UInt8 = 0
        
        // The correct response is at least 3 bytes long: Response Op Code, Request Op Code and Status
        if data.count >= 3 {
            (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
            (data as NSData).getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
            (data as NSData).getBytes(&status, range: NSRange(location: 2, length: 1))
        }
        
        self.opCode        = SecureDFUOpCode(rawValue: opCode)
        self.requestOpCode = SecureDFUOpCode(rawValue: requestOpCode)
        self.status        = SecureDFUResultCode(rawValue: status)
        
        // Parse response data in case of a success
        if self.status == .success {
            switch self.requestOpCode {
            case .some(.readObjectInfo):
                var maxSize : UInt32 = 0
                var offset  : UInt32 = 0
                var crc     : UInt32 = 0
                
                // The correct reponse for Read Object Info has additional 12 bytes: Max Object Size, Offset and CRC
                if data.count == 3 + 3 * 4 {
                    (data as NSData).getBytes(&maxSize, range: NSRange(location: 3, length: 4))
                    (data as NSData).getBytes(&offset, range: NSRange(location: 7, length: 4))
                    (data as NSData).getBytes(&crc, range: NSRange(location: 11, length: 4))
                }
                
                self.maxSize = maxSize
                self.offset  = offset
                self.crc     = crc
                self.error   = nil
            case .some(.calculateChecksum):
                var offset : UInt32 = 0
                var crc    : UInt32 = 0
                
                // The correct reponse for Calculate Checksum has additional 8 bytes: Offset and CRC
                if data.count == 3 + 2 * 4 {
                    (data as NSData).getBytes(&offset, range: NSRange(location: 3, length: 4))
                    (data as NSData).getBytes(&crc, range: NSRange(location: 7, length: 4))
                }
                
                self.maxSize = 0
                self.offset  = offset
                self.crc     = crc
                self.error   = nil
            default:
                self.maxSize = 0
                self.offset  = 0
                self.crc     = 0
                self.error   = nil
            }
        } else if self.status == .extendedError {
            // If extended error was received, parse the extended error code
            var error : UInt8 = 0
            
            // The correct response for Read Error request has 4 bytes. The 4th byte is the extended error code
            if data.count == 4 {
                (data as NSData).getBytes(&error, range: NSRange(location: 3, length: 1))
            }
            
            self.maxSize = 0
            self.offset  = 0
            self.crc     = 0
            self.error   = SecureDFUExtendedErrorCode(rawValue: error)
        } else {
            self.maxSize = 0
            self.offset  = 0
            self.crc     = 0
            self.error   = nil
        }
    
        if self.opCode != .responseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }

    var description: String {
        if status == .success {
            switch requestOpCode {
            case .some(.readObjectInfo):
                // Max size for a command object is usually around 256. Let's say 1024, just to be sure. This is only for logging, so may be wrong.
                return String(format: "\(maxSize! > 1024 ? "Data" : "Command") object info (Max size = \(maxSize!), Offset = \(offset!), CRC = %08X)", crc!)
            case .some(.calculateChecksum):
                return String(format: "Checksum (Offset = \(offset!), CRC = %08X)", crc!)
            default:
                // Other responses are either not logged, or logged by service or executor, so this 'default' should never be called
                break
            }
        } else if status == .extendedError {
            if let error = error {
                return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue), Extended Error \(error.rawValue) = \(error.description))"
            } else {
                return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue), Unsupported Extended Error value)"
            }
        }
        return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue))"
    }
}

internal struct SecureDFUPacketReceiptNotification {
    let opCode        : SecureDFUOpCode?
    let requestOpCode : SecureDFUOpCode?
    let resultCode    : SecureDFUResultCode?
    let offset        : UInt32
    let crc           : UInt32

    init?(_ data: Data) {
        var opCode        : UInt8 = 0
        var requestOpCode : UInt8 = 0
        var resultCode    : UInt8 = 0

        (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
        (data as NSData).getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        (data as NSData).getBytes(&resultCode, range: NSRange(location: 2, length: 1))

        self.opCode         = SecureDFUOpCode(rawValue: opCode)
        self.requestOpCode  = SecureDFUOpCode(rawValue: requestOpCode)
        self.resultCode     = SecureDFUResultCode(rawValue: resultCode)

        if self.opCode != .responseCode {
            return nil
        }
        if self.requestOpCode != .calculateChecksum {
            return nil
        }
        if self.resultCode != .success {
            return nil
        }

        var offsetResult: UInt32 = 0
        (data as NSData).getBytes(&offsetResult, range: NSRange(location: 3, length: 4))
        self.offset = offsetResult
        
        var crcResult: UInt32 = 0
        (data as NSData).getBytes(&crcResult, range: NSRange(location: 7, length: 4))
        self.crc = crcResult
    }
}

internal class SecureDFUControlPoint : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "8EC90001-F315-4F60-9FB8-838830DAEA50")
    
    static func matches(_ characteristic: CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    private var characteristic: CBCharacteristic
    private var logger: LoggerHelper
    
    private var success:  Callback?
    private var response: SecureDFUResponseCallback?
    private var proceed:  ProgressCallback?
    private var report:   ErrorCallback?

    internal var valid: Bool {
        return characteristic.properties.isSuperset(of: [CBCharacteristicProperties.write, CBCharacteristicProperties.notify])
    }
    
    // MARK: - Initialization
    init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }

    func peripheralDidReceiveObject() {
        proceed = nil
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
     Sends given request to the DFU Control Point characteristic. Reports success or an error
     using callbacks.
     
     - parameter request: request to be sent
     - parameter success: method called when peripheral reported with status success
     - parameter report:  method called in case of an error
     */
    func send(_ request: SecureDFURequest, onSuccess success: Callback?, onError report: ErrorCallback?) {
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
    
    /**
     Sends given request to the DFU Control Point characteristic. Reports received data or an error
     using callbacks.
     
     - parameter request:  request to be sent
     - parameter response: method called when peripheral sent a notification with requested data and status success
     - parameter report:   method called in case of an error
     */
    func send(_ request: SecureDFURequest, onResponse response: SecureDFUResponseCallback?, onError report: ErrorCallback?) {
        // Save callbacks and parameter
        self.response = response
        self.report   = report
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.v("Writing to characteristic \(characteristic.uuid.uuidString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(characteristic.uuid.uuidString), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    /**
     Sets the callbacks used later on when a Packet Receipt Notification is received, a device reported an error or the whole firmware has been sent. 
     Sending the firmware is done using DFU Packet characteristic.
     
     - parameter success: method called when peripheral reported with status success
     - parameter proceed: method called the a PRN has been received and sending following data can be resumed
     - parameter report:  method called in case of an error
     */
    func waitUntilUploadComplete(onSuccess success: Callback?, onPacketReceiptNofitication proceed: ProgressCallback?, onError report: ErrorCallback?) {
        // Save callbacks. The proceed callback will be called periodically whenever a packet receipt notification is received. It resumes uploading.
        self.success = success
        self.proceed = proceed
        self.report  = report

        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.a("Uploading firmware...")
        logger.v("Sending firmware to DFU Packet characteristic...")
    }

    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.e("Enabling notifications failed")
            logger.e(error!)
            report?(.enablingControlPointFailed, "Enabling notifications failed")
        } else {
            logger.v("Notifications enabled for \(characteristic.uuid.uuidString)")
            logger.a("Secure DFU Control Point notifications enabled")
            success?()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // This method, according to the iOS documentation, should be called only after writing with response to a characteristic.
        // However, on iOS 10 this method is called even after writing without response, which is a bug.
        // The DFU Control Point characteristic always writes with response, in oppose to the DFU Packet, which uses write without response.
        guard characteristic.uuid.isEqual(SecureDFUControlPoint.UUID) else {
            return
        }
        
        if error != nil {
            logger.e("Writing to characteristic failed")
            logger.e(error!)
            report?(.writingCharacteristicFailed, "Writing to characteristic failed")
        } else {
            logger.i("Data written to \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Ignore updates received for other characteristics
        guard characteristic.uuid.isEqual(SecureDFUControlPoint.UUID) else {
            return
        }
        
        if error != nil {
            // This characteristic is never read, the error may only pop up when notification is received
            logger.e("Receiving notification failed")
            logger.e(error!)
            report?(.receivingNotificationFailed, "Receiving notification failed")
        } else {
            // During the upload we may get either a Packet Receipt Notification, or a Response with status code
            if proceed != nil {
                if let prn = SecureDFUPacketReceiptNotification(characteristic.value!) {
                    proceed!(prn.offset) // The CRC is not verified after receiving a PRN, only the offset is
                    return
                }
            }
            //Otherwise...    
            logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x): \(characteristic.value!.hexString)")

            // Parse response received
            let dfuResponse = SecureDFUResponse(characteristic.value!)
            if let dfuResponse = dfuResponse {
                if dfuResponse.status == .success {
                    switch dfuResponse.requestOpCode! {
                    case .readObjectInfo, .calculateChecksum:
                        logger.a("\(dfuResponse.description) received")
                        response?(dfuResponse)
                    case .createObject, .setPRNValue, .execute:
                        // Don't log, executor or service will do it for us
                        success?()
                    default:
                        logger.a("\(dfuResponse.description) received")
                        success?()
                    }
                } else if dfuResponse.status == .extendedError {
                    // An extended error was received
                    logger.e("Error \(dfuResponse.error!.code): \(dfuResponse.error!.description)")
                    // The returned errod code is incremented by 10 to match Secure DFU remote codes
                    report?(DFUError(rawValue: Int(dfuResponse.status!.code) + 10)!, dfuResponse.error!.description)
                } else {
                    logger.e("Error \(dfuResponse.status!.code): \(dfuResponse.status!.description)")
                    // The returned errod code is incremented by 10 to match Secure DFU remote codes
                    report?(DFUError(rawValue: Int(dfuResponse.status!.code) + 10)!, dfuResponse.status!.description)
                }
            } else {
                logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
                report?(.unsupportedResponse, "Unsupported response received: 0x\(characteristic.value!.hexString)")
            }
        }
    }
}
