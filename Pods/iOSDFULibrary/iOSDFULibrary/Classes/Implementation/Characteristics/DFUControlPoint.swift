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

internal typealias ProgressCallback = (bytesReceived:Int) -> Void

internal enum OpCode : UInt8 {
    case StartDfu = 1
    case InitDfuParameters = 2
    case ReceiveFirmwareImage = 3
    case ValidateFirmware = 4
    case ActivateAndReset = 5
    case Reset = 6
    case ReportReceivedImageSize = 7 // unused in this library
    case PacketReceiptNotificationRequest = 8
    case ResponseCode = 16
    case PacketReceiptNotification = 17
    
    var code:UInt8 {
        return rawValue
    }
}

internal enum InitDfuParametersRequest : UInt8 {
    case ReceiveInitPacket  = 0
    case InitPacketComplete = 1
    
    var code:UInt8 {
        return rawValue
    }
}

internal enum Request {
    case JumpToBootloader
    case StartDfu(type:UInt8)
    case StartDfu_v1
    case InitDfuParameters(req:InitDfuParametersRequest)
    case InitDfuParameters_v1
    case ReceiveFirmwareImage
    case ValidateFirmware
    case ActivateAndReset
    case Reset
    case PacketReceiptNotificationRequest(number:UInt16)
    
    var data : NSData {
        switch self {
        case .JumpToBootloader:
            let bytes:[UInt8] = [OpCode.StartDfu.code, FIRMWARE_TYPE_APPLICATION]
            return NSData(bytes: bytes, length: 2)
        case .StartDfu(let type):
            let bytes:[UInt8] = [OpCode.StartDfu.code, type]
            return NSData(bytes: bytes, length: 2)
        case .StartDfu_v1:
            let bytes:[UInt8] = [OpCode.StartDfu.code]
            return NSData(bytes: bytes, length: 1)
        case .InitDfuParameters(let req):
            let bytes:[UInt8] = [OpCode.InitDfuParameters.code, req.code]
            return NSData(bytes: bytes, length: 2)
        case .InitDfuParameters_v1:
            let bytes:[UInt8] = [OpCode.InitDfuParameters.code]
            return NSData(bytes: bytes, length: 1)
        case .ReceiveFirmwareImage:
            let bytes:[UInt8] = [OpCode.ReceiveFirmwareImage.code]
            return NSData(bytes: bytes, length: 1)
        case .ValidateFirmware:
            let bytes:[UInt8] = [OpCode.ValidateFirmware.code]
            return NSData(bytes: bytes, length: 1)
        case .ActivateAndReset:
            let bytes:[UInt8] = [OpCode.ActivateAndReset.code]
            return NSData(bytes: bytes, length: 1)
        case .Reset:
            let bytes:[UInt8] = [OpCode.Reset.code]
            return NSData(bytes: bytes, length: 1)
        case .PacketReceiptNotificationRequest(let number):
            let data = NSMutableData(capacity: 5)!
            let bytes:[UInt8] = [OpCode.PacketReceiptNotificationRequest.code]
            data.appendBytes(bytes, length: 1)
            var n = number.littleEndian
            withUnsafePointer(&n) {
                data.appendBytes(UnsafePointer($0), length: 2)
            }
            return NSData(data: data)
        }
    }
    
    var description : String {
        switch self {
        case .JumpToBootloader:
            return "Jump to bootloader (Op Code = 1, Upload Mode = 4)"
        case .StartDfu(let type):
            return "Start DFU (Op Code = 1, Upload Mode = \(type))"
        case .StartDfu_v1:
            return "Start DFU (Op Code = 1)"
        case .InitDfuParameters(_):
            return "Initialize DFU Parameters"
        case .InitDfuParameters_v1:
            return "Initialize DFU Parameters"
        case .ReceiveFirmwareImage:
            return "Receive Firmware Image (Op Code = 3)"
        case .ValidateFirmware:
            return "Validate Firmware (Op Code = 4)"
        case .ActivateAndReset:
            return "Activate and Reset (Op Code = 5)"
        case .Reset:
            return "Reset (Op Code = 6)"
        case .PacketReceiptNotificationRequest(let number):
            return "Packet Receipt Notif Req (Op Code = 8, Value = \(number))"
        }
    }
}

internal enum StatusCode : UInt8 {
    case Success              = 1
    case InvalidState         = 2
    case NotSupported         = 3
    case DataSizeExceedsLimit = 4
    case CRCError             = 5
    case OperationFailed      = 6
    
    var description:String {
        switch self {
        case .Success: return "Success"
        case .InvalidState: return "Device is in invalid state"
        case .NotSupported: return "Operation not supported"
        case .DataSizeExceedsLimit:  return "Data size exceeds limit"
        case .CRCError: return "CRC Error"
        case .OperationFailed: return "Operation failed"
        }
    }
    
    var code:UInt8 {
        return rawValue
    }
}

internal struct Response {
    let opCode:OpCode?
    let requestOpCode:OpCode?
    let status:StatusCode?
    
    init?(_ data:NSData) {
        var opCode:UInt8 = 0
        var requestOpCode:UInt8 = 0
        var status:UInt8 = 0
        data.getBytes(&opCode, range: NSRange(location: 0, length: 1))
        data.getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        data.getBytes(&status, range: NSRange(location: 2, length: 1))
        self.opCode = OpCode(rawValue: opCode)
        self.requestOpCode = OpCode(rawValue: requestOpCode)
        self.status = StatusCode(rawValue: status)
        
        if self.opCode != OpCode.ResponseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }
    
    var description:String {
        return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue))"
    }
}

internal struct PacketReceiptNotification {
    let opCode:OpCode?
    let bytesReceived:Int
    
    init?(_ data:NSData) {
        var opCode:UInt8 = 0
        data.getBytes(&opCode, range: NSRange(location: 0, length: 1))
        self.opCode = OpCode(rawValue: opCode)
        
        if self.opCode != OpCode.PacketReceiptNotification {
            return nil
        }
        
        var bytesReceived:UInt32 = 0
        data.getBytes(&bytesReceived, range: NSRange(location: 1, length: 4))
        self.bytesReceived = Int(bytesReceived)
    }
}

@objc internal class DFUControlPoint : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "00001531-1212-EFDE-1523-785FEABCD123")
    
    static func matches(characteristic:CBCharacteristic) -> Bool {
        return characteristic.UUID.isEqual(UUID)
    }
    
    private var characteristic:CBCharacteristic
    private var logger:LoggerHelper
    
    private var success:Callback?
    private var proceed:ProgressCallback?
    private var report:ErrorCallback?
    private var request:Request?
    private var uploadStartTime:CFAbsoluteTime?
    private var resetSent:Bool = false
    
    var valid:Bool {
        return characteristic.properties.isSupersetOf([CBCharacteristicProperties.Write, CBCharacteristicProperties.Notify])
    }
    
    // MARK: - Initialization
    
    init(_ characteristic:CBCharacteristic, _ logger:LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    
    /**
    Enables notifications for the DFU ControlPoint characteristics. Reports success or an error 
    using callbacks.
    
    - parameter success: method called when notifications were successfully enabled
    - parameter report:  method called in case of an error
    */
    func enableNotifications(onSuccess success:Callback?, onError report:ErrorCallback?) {
        // Save callbacks
        self.success = success
        self.report = report
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.v("Enabling notifiactions for \(DFUControlPoint.UUID.UUIDString)...")
        logger.d("peripheral.setNotifyValue(true, forCharacteristic: \(DFUControlPoint.UUID.UUIDString))")
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
    }
    
    func send(request:Request, onSuccess success:Callback?, onError report:ErrorCallback?) {
        // Save callbacks and parameter
        self.success = success
        self.report = report
        self.request = request
        self.resetSent = false
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        switch request {
        case .InitDfuParameters(let req):
            if req == InitDfuParametersRequest.ReceiveInitPacket {
                logger.a("Writing \(request.description)...")
            }
        case .InitDfuParameters_v1:
            logger.a("Writing \(request.description)...")
        case .JumpToBootloader, .ActivateAndReset, .Reset:
            // Those three requests may not be confirmed by the remote DFU target. The device may be restarted before sending the ACK.
            // This would cause an error in peripheral:didWriteValueForCharacteristic:error, which can be ignored in this case.
            self.resetSent = true
        default:
            break
        }
        logger.v("Writing to characteristic \(DFUControlPoint.UUID.UUIDString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), forCharacteristic: \(DFUControlPoint.UUID.UUIDString), type: WithResponse)")
        peripheral.writeValue(request.data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func waitUntilUploadComplete(onSuccess success:Callback?, onPacketReceiptNofitication proceed:ProgressCallback?, onError report:ErrorCallback?) {
        // Save callbacks. The proceed callback will be called periodically whenever a packet receipt notification is received. It resumes uploading.
        self.success = success
        self.proceed = proceed
        self.report = report
        self.uploadStartTime = CFAbsoluteTimeGetCurrent()
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        logger.a("Uploading firmware...")
        logger.v("Sending firmware DFU Packet characteristic...")
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            logger.e("Enabling notifications failed")
            logger.e(error!)
            report?(error:DFUError.EnablingControlPointFailed, withMessage:"Enabling notifications failed")
        } else {
            logger.v("Notifications enabled for \(DFUVersion.UUID.UUIDString)")
            logger.a("DFU Control Point notifications enabled")
            success?()
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            if !self.resetSent {
                logger.e("Writing to characteristic failed")
                logger.e(error!)
                report?(error:DFUError.WritingCharacteristicFailed, withMessage:"Writing to characteristic failed")
            } else {
                // When a 'JumpToBootloader', 'Activate and Reset' or 'Reset' command is sent the device may reset before sending the acknowledgement.
                // This is not a blocker, as the device did disconnect and reset successfully.
                logger.a("\(request!.description) request sent")
                logger.w("Device disconnected before sending ACK")
                logger.w(error!)
                success?()
            }
        } else {
            logger.i("Data written to \(DFUControlPoint.UUID.UUIDString)")
            
            switch request! {
            case .StartDfu(_), .StartDfu_v1,  .ValidateFirmware:
                logger.a("\(request!.description) request sent")
                // do not call success until we get a notification
            case .JumpToBootloader, .ReceiveFirmwareImage, .ActivateAndReset, .Reset, .PacketReceiptNotificationRequest(_):
                logger.a("\(request!.description) request sent")
                // there will be no notification send after these requests, call success() immetiatelly
                // (for .ReceiveFirmwareImage the notification will be sent after firmware upload is complete)
                success?()
            case .InitDfuParameters(_), .InitDfuParameters_v1:
                // Log was created before sending the Op Code
                
                // do not call success until we get a notification
                break;
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            // This characteristic is never read, the error may only pop up when notification is received
            logger.e("Receiving notification failed")
            logger.e(error!)
            report?(error:DFUError.ReceivingNotificatinoFailed, withMessage:"Receiving notification failed")
        } else {
            // During the upload we may get either a Packet Receipt Notification, or a Response with status code
            if proceed != nil {
                if let prn = PacketReceiptNotification(characteristic.value!) {
                    proceed!(bytesReceived: prn.bytesReceived)
                    return
                }
            }
            // Otherwise...
            proceed = nil
            
            logger.i("Notification received from \(DFUVersion.UUID.UUIDString), value (0x):\(characteristic.value!.hexString)")
            
            // Parse response received
            let response = Response(characteristic.value!)
            if let response = response {
                logger.a("\(response.description) received")
                
                if response.status == StatusCode.Success {
                    switch response.requestOpCode! {
                    case .InitDfuParameters:
                        logger.a("Initialize DFU Parameters completed")
                    case .ReceiveFirmwareImage:
                        let interval = CFAbsoluteTimeGetCurrent() - uploadStartTime! as CFTimeInterval
                        logger.a("Upload completed in \(interval.format(".2")) seconds")
                    default:
                        break
                    }
                    success?()
                } else {
                    logger.e("Error \(response.status!.code): \(response.status!.description)")
                    report?(error: DFUError(rawValue: Int(response.status!.rawValue))!, withMessage: response.status!.description)
                }
            } else {
                logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
                report?(error:DFUError.UnsupportedResponse, withMessage:"Writing to characteristic failed")
            }
        }
    }
}
