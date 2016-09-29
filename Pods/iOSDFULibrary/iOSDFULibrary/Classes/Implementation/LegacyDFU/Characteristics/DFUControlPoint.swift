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

internal typealias ProgressCallback = (_ bytesReceived:Int) -> Void

internal enum DFUOpCode : UInt8 {
    case startDfu                           = 1
    case initDfuParameters                  = 2
    case receiveFirmwareImage               = 3
    case validateFirmware                   = 4
    case activateAndReset                   = 5
    case reset                              = 6
    case reportReceivedImageSize            = 7 // unused in this library
    case packetReceiptNotificationRequest   = 8
    case responseCode                       = 16
    case packetReceiptNotification          = 17
    
    var code:UInt8 {
        return rawValue
    }
}

internal enum InitDfuParametersRequest : UInt8 {
    case receiveInitPacket  = 0
    case initPacketComplete = 1
    
    var code:UInt8 {
        return rawValue
    }
}

internal enum Request {
    case jumpToBootloader
    case startDfu(type:UInt8)
    case startDfu_v1
    case initDfuParameters(req:InitDfuParametersRequest)
    case initDfuParameters_v1
    case receiveFirmwareImage
    case validateFirmware
    case activateAndReset
    case reset
    case packetReceiptNotificationRequest(number:UInt16)
    
    var data : Data {
        switch self {
        case .jumpToBootloader:
            let bytes:[UInt8] = [DFUOpCode.startDfu.code, FIRMWARE_TYPE_APPLICATION]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 2)
        case .startDfu(let type):
            let bytes:[UInt8] = [DFUOpCode.startDfu.code, type]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 2)
        case .startDfu_v1:
            let bytes:[UInt8] = [DFUOpCode.startDfu.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 1)
        case .initDfuParameters(let req):
            let bytes:[UInt8] = [DFUOpCode.initDfuParameters.code, req.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 2)
        case .initDfuParameters_v1:
            let bytes:[UInt8] = [DFUOpCode.initDfuParameters.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 1)
        case .receiveFirmwareImage:
            let bytes:[UInt8] = [DFUOpCode.receiveFirmwareImage.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 1)
        case .validateFirmware:
            let bytes:[UInt8] = [DFUOpCode.validateFirmware.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 1)
        case .activateAndReset:
            let bytes:[UInt8] = [DFUOpCode.activateAndReset.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 1)
        case .reset:
            let bytes:[UInt8] = [DFUOpCode.reset.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: 1)
        case .packetReceiptNotificationRequest(let number):
            let data = NSMutableData(capacity: 5)!
            let bytes:[UInt8] = [DFUOpCode.packetReceiptNotificationRequest.code]
            data.append(bytes, length: 1)
            var n = number.littleEndian
            withUnsafePointer(to: &n) {
                data.append(UnsafeRawPointer($0), length: 2)
            }
            return (NSData(data: data as Data) as Data)
        }
    }
    
    var description : String {
        switch self {
        case .jumpToBootloader:
            return "Jump to bootloader (Op Code = 1, Upload Mode = 4)"
        case .startDfu(let type):
            return "Start DFU (Op Code = 1, Upload Mode = \(type))"
        case .startDfu_v1:
            return "Start DFU (Op Code = 1)"
        case .initDfuParameters(_):
            return "Initialize DFU Parameters"
        case .initDfuParameters_v1:
            return "Initialize DFU Parameters"
        case .receiveFirmwareImage:
            return "Receive Firmware Image (Op Code = 3)"
        case .validateFirmware:
            return "Validate Firmware (Op Code = 4)"
        case .activateAndReset:
            return "Activate and Reset (Op Code = 5)"
        case .reset:
            return "Reset (Op Code = 6)"
        case .packetReceiptNotificationRequest(let number):
            return "Packet Receipt Notif Req (Op Code = 8, Value = \(number))"
        }
    }
}

internal enum DFUResultCode : UInt8 {
    case success              = 1
    case invalidState         = 2
    case notSupported         = 3
    case dataSizeExceedsLimit = 4
    case crcError             = 5
    case operationFailed      = 6
    
    var description:String {
        switch self {
        case .success: return "Success"
        case .invalidState: return "Device is in invalid state"
        case .notSupported: return "Operation not supported"
        case .dataSizeExceedsLimit:  return "Data size exceeds limit"
        case .crcError: return "CRC Error"
        case .operationFailed: return "Operation failed"
        }
    }
    
    var code:UInt8 {
        return rawValue
    }
}

internal struct Response {
    let opCode:DFUOpCode?
    let requestOpCode:DFUOpCode?
    let status:DFUResultCode?
    
    init?(_ data:Data) {
        var opCode:UInt8 = 0
        var requestOpCode:UInt8 = 0
        var status:UInt8 = 0
        (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
        (data as NSData).getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        (data as NSData).getBytes(&status, range: NSRange(location: 2, length: 1))
        self.opCode = DFUOpCode(rawValue: opCode)
        self.requestOpCode = DFUOpCode(rawValue: requestOpCode)
        self.status = DFUResultCode(rawValue: status)
        
        if self.opCode != DFUOpCode.responseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }
    
    var description:String {
        return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue))"
    }
}

internal struct PacketReceiptNotification {
    let opCode:DFUOpCode?
    let bytesReceived:Int
    
    init?(_ data:Data) {
        var opCode:UInt8 = 0
        (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
        self.opCode = DFUOpCode(rawValue: opCode)
        
        if self.opCode != DFUOpCode.packetReceiptNotification {
            return nil
        }
        
        var bytesReceived:UInt32 = 0
        (data as NSData).getBytes(&bytesReceived, range: NSRange(location: 1, length: 4))
        self.bytesReceived = Int(bytesReceived)
    }
}

@objc internal class DFUControlPoint : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "00001531-1212-EFDE-1523-785FEABCD123")
    
    static func matches(_ characteristic:CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    fileprivate var characteristic:CBCharacteristic
    fileprivate var logger:LoggerHelper
    
    fileprivate var success:Callback?
    fileprivate var proceed:ProgressCallback?
    fileprivate var report:ErrorCallback?
    fileprivate var request:Request?
    fileprivate var uploadStartTime:CFAbsoluteTime?
    fileprivate var resetSent:Bool = false
    
    var valid:Bool {
        return characteristic.properties.isSuperset(of: [CBCharacteristicProperties.write, CBCharacteristicProperties.notify])
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
        
        logger.v("Enabling notifiactions for \(DFUControlPoint.UUID.uuidString)...")
        logger.d("peripheral.setNotifyValue(true, forCharacteristic: \(DFUControlPoint.UUID.uuidString))")
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func send(_ request:Request, onSuccess success:Callback?, onError report:ErrorCallback?) {
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
        case .initDfuParameters(let req):
            if req == InitDfuParametersRequest.receiveInitPacket {
                logger.a("Writing \(request.description)...")
            }
        case .initDfuParameters_v1:
            logger.a("Writing \(request.description)...")
        case .jumpToBootloader, .activateAndReset, .reset:
            // Those three requests may not be confirmed by the remote DFU target. The device may be restarted before sending the ACK.
            // This would cause an error in peripheral:didWriteValueForCharacteristic:error, which can be ignored in this case.
            self.resetSent = true
        default:
            break
        }
        logger.v("Writing to characteristic \(DFUControlPoint.UUID.uuidString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), forCharacteristic: \(DFUControlPoint.UUID.uuidString), type: WithResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
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
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.e("Enabling notifications failed")
            logger.e(error!)
            report?(DFUError.enablingControlPointFailed, "Enabling notifications failed")
        } else {
            logger.v("Notifications enabled for \(DFUVersion.UUID.uuidString)")
            logger.a("DFU Control Point notifications enabled")
            success?()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            if !self.resetSent {
                logger.e("Writing to characteristic failed")
                logger.e(error!)
                report?(DFUError.writingCharacteristicFailed, "Writing to characteristic failed")
            } else {
                // When a 'JumpToBootloader', 'Activate and Reset' or 'Reset' command is sent the device may reset before sending the acknowledgement.
                // This is not a blocker, as the device did disconnect and reset successfully.
                logger.a("\(request!.description) request sent")
                logger.w("Device disconnected before sending ACK")
                logger.w(error!)
                success?()
            }
        } else {
            logger.i("Data written to \(DFUControlPoint.UUID.uuidString)")
            
            switch request! {
            case .startDfu(_), .startDfu_v1,  .validateFirmware:
                logger.a("\(request!.description) request sent")
                // do not call success until we get a notification
            case .jumpToBootloader, .activateAndReset, .reset, .packetReceiptNotificationRequest(_):
                logger.a("\(request!.description) request sent")
                // there will be no notification send after these requests, call success() immetiatelly
                // (for .ReceiveFirmwareImage the notification will be sent after firmware upload is complete)
                success?()
            case .initDfuParameters(_), .initDfuParameters_v1:
                // Log was created before sending the Op Code
                
                // do not call success until we get a notification
                break
            case .receiveFirmwareImage:
                if proceed == nil {
                    success?()
                }
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            // This characteristic is never read, the error may only pop up when notification is received
            logger.e("Receiving notification failed")
            logger.e(error!)
            report?(DFUError.receivingNotificationFailed, "Receiving notification failed")
        } else {
            // During the upload we may get either a Packet Receipt Notification, or a Response with status code
            if proceed != nil {
                if let prn = PacketReceiptNotification(characteristic.value!) {
                    proceed!(prn.bytesReceived)
                    return
                }
            }
            // Otherwise...
            proceed = nil
            
            logger.i("Notification received from \(DFUVersion.UUID.uuidString), value (0x):\(characteristic.value!.hexString)")
            
            // Parse response received
            let response = Response(characteristic.value!)
            if let response = response {
                logger.a("\(response.description) received")
                
                if response.status == DFUResultCode.success {
                    switch response.requestOpCode! {
                    case .initDfuParameters:
                        logger.a("Initialize DFU Parameters completed")
                    case .receiveFirmwareImage:
                        let interval = CFAbsoluteTimeGetCurrent() - uploadStartTime! as CFTimeInterval
                        logger.a("Upload completed in \(interval.format(".2")) seconds")
                    default:
                        break
                    }
                    success?()
                } else {
                    logger.e("Error \(response.status!.code): \(response.status!.description)")
                    report?(DFUError(rawValue: Int(response.status!.rawValue))!, response.status!.description)
                }
            } else {
                logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
                report?(DFUError.unsupportedResponse, "Writing to characteristic failed")
            }
        }
    }
}
