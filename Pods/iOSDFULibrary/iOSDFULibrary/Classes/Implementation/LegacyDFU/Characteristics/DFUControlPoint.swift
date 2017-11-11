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
    
    var code: UInt8 {
        return rawValue
    }
}

internal enum InitDfuParametersRequest : UInt8 {
    case receiveInitPacket  = 0
    case initPacketComplete = 1
    
    var code: UInt8 {
        return rawValue
    }
}

internal enum Request {
    case jumpToBootloader
    case startDfu(type: UInt8)
    case startDfu_v1
    case initDfuParameters(req: InitDfuParametersRequest)
    case initDfuParameters_v1
    case receiveFirmwareImage
    case validateFirmware
    case activateAndReset
    case reset
    case packetReceiptNotificationRequest(number: UInt16)
    
    var data : Data {
        switch self {
        case .jumpToBootloader:
            return Data(bytes: [DFUOpCode.startDfu.code, FIRMWARE_TYPE_APPLICATION])
        case .startDfu(let type):
            return Data(bytes: [DFUOpCode.startDfu.code, type])
        case .startDfu_v1:
            return Data(bytes: [DFUOpCode.startDfu.code])
        case .initDfuParameters(let req):
            return Data(bytes: [DFUOpCode.initDfuParameters.code, req.code])
        case .initDfuParameters_v1:
            return Data(bytes: [DFUOpCode.initDfuParameters.code])
        case .receiveFirmwareImage:
            return Data(bytes: [DFUOpCode.receiveFirmwareImage.code])
        case .validateFirmware:
            return Data(bytes: [DFUOpCode.validateFirmware.code])
        case .activateAndReset:
            return Data(bytes: [DFUOpCode.activateAndReset.code])
        case .reset:
            return Data(bytes: [DFUOpCode.reset.code])
        case .packetReceiptNotificationRequest(let number):
            var data = Data(bytes: [DFUOpCode.packetReceiptNotificationRequest.code])
            data += number.littleEndian
            return data
        }
    }
    
    var description : String {
        switch self {
        case .jumpToBootloader:     return "Jump to bootloader (Op Code = 1, Upload Mode = 4)"
        case .startDfu(let type):   return "Start DFU (Op Code = 1, Upload Mode = \(type))"
        case .startDfu_v1:          return "Start DFU (Op Code = 1)"
        case .initDfuParameters(_): return "Initialize DFU Parameters"
        case .initDfuParameters_v1: return "Initialize DFU Parameters"
        case .receiveFirmwareImage: return "Receive Firmware Image (Op Code = 3)"
        case .validateFirmware:     return "Validate Firmware (Op Code = 4)"
        case .activateAndReset:     return "Activate and Reset (Op Code = 5)"
        case .reset:                return "Reset (Op Code = 6)"
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
    
    var description: String {
        switch self {
        case .success:              return "Success"
        case .invalidState:         return "Device is in invalid state"
        case .notSupported:         return "Operation not supported"
        case .dataSizeExceedsLimit: return "Data size exceeds limit"
        case .crcError:             return "CRC Error"
        case .operationFailed:      return "Operation failed"
        }
    }
    
    var code: UInt8 {
        return rawValue
    }
}

internal struct Response {
    let opCode        : DFUOpCode?
    let requestOpCode : DFUOpCode?
    let status        : DFUResultCode?
    
    init?(_ data: Data) {
        let opCode        : UInt8 = data[0]
        let requestOpCode : UInt8 = data[1]
        let status        : UInt8 = data[2]
        
        self.opCode        = DFUOpCode(rawValue: opCode)
        self.requestOpCode = DFUOpCode(rawValue: requestOpCode)
        self.status        = DFUResultCode(rawValue: status)
        
        if self.opCode != .responseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }
    
    var description: String {
        return "Response (Op Code = \(requestOpCode!.rawValue), Status = \(status!.rawValue))"
    }
}

internal struct PacketReceiptNotification {
    let opCode        : DFUOpCode?
    let bytesReceived : UInt32
    
    init?(_ data: Data) {
        let opCode: UInt8 = data[0]
        
        self.opCode = DFUOpCode(rawValue: opCode)
        
        if self.opCode != .packetReceiptNotification {
            return nil
        }
        
        // According to https://github.com/NordicSemiconductor/IOS-Pods-DFU-Library/issues/54
        // in SDK 5.2.0.39364 the bytesReveived value in a PRN packet is 16-bit long, instad of 32-bit.
        // However, the packet is still 5 bytes long and the two last bytes are 0x00-00.
        // This has to be taken under consideration when comparing number of bytes sent and received as
        // the latter counter may rewind if fw size is > 0xFFFF bytes (LegacyDFUService:L372).
        let bytesReceived: UInt32 = data.subdata(in: 1 ..< 4).withUnsafeBytes { $0.pointee }
        self.bytesReceived = bytesReceived
    }
}

@objc internal class DFUControlPoint : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "00001531-1212-EFDE-1523-785FEABCD123")
    
    static func matches(_ characteristic: CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    private var characteristic: CBCharacteristic
    private var logger: LoggerHelper
    
    private var success: Callback?
    private var proceed: ProgressCallback?
    private var report:  ErrorCallback?
    private var request: Request?
    private var uploadStartTime: CFAbsoluteTime?
    private var resetSent = false
    
    internal var valid: Bool {
        return characteristic.properties.isSuperset(of: [.write, .notify])
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
     Sends given request to the DFU Control Point characteristic. Reports success or an error
     using callbacks.
     
     - parameter request: request to be sent
     - parameter success: method called when peripheral reported with status success
     - parameter report:  method called in case of an error
     */
    func send(_ request: Request, onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Save callbacks and parameter
        self.success   = success
        self.report    = report
        self.request   = request
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
            resetSent = true
        default:
            break
        }
        logger.v("Writing to characteristic \(characteristic.uuid.uuidString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(characteristic.uuid.uuidString), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    /**
     Sets the callbacks used later on when a Packet Receipt Notification is received, a device reported an error or the whole firmware has been sent
     and the notification with success status was received. Sending the firmware is done using DFU Packet characteristic.
     
     - parameter success: method called when peripheral reported with status success
     - parameter proceed: method called the a PRN has been received and sending following data can be resumed
     - parameter report:  method called in case of an error
     */
    func waitUntilUploadComplete(onSuccess success: Callback?, onPacketReceiptNofitication proceed: ProgressCallback?, onError report: ErrorCallback?) {
        // Save callbacks. The proceed callback will be called periodically whenever a packet receipt notification is received. It resumes uploading.
        self.success = success
        self.proceed = proceed
        self.report  = report
        self.uploadStartTime = CFAbsoluteTimeGetCurrent()
        
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
            logger.a("DFU Control Point notifications enabled")
            success?()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // This method, according to the iOS documentation, should be called only after writing with response to a characteristic.
        // However, on iOS 10 this method is called even after writing without response, which is a bug.
        // The DFU Control Point characteristic always writes with response, in oppose to the DFU Packet, which uses write without response.
        guard characteristic.uuid.isEqual(DFUControlPoint.UUID) else {
            return
        }
        
        if error != nil {
            if !resetSent {
                logger.e("Writing to characteristic failed")
                logger.e(error!)
                report?(.writingCharacteristicFailed, "Writing to characteristic failed")
            } else {
                // When a 'JumpToBootloader', 'Activate and Reset' or 'Reset' command is sent the device may reset before sending the acknowledgement.
                // This is not a blocker, as the device did disconnect and reset successfully.
                logger.a("\(request!.description) request sent")
                logger.w("Device disconnected before sending ACK")
                logger.w(error!)
                success?()
            }
        } else {
            logger.i("Data written to \(characteristic.uuid.uuidString)")
            
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
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Ignore updates received for other characteristics
        guard characteristic.uuid.isEqual(DFUControlPoint.UUID) else {
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
                if let prn = PacketReceiptNotification(characteristic.value!) {
                    proceed!(prn.bytesReceived)
                    return
                }
            }
            // Otherwise...
            logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x): \(characteristic.value!.hexString)")
            
            // Parse response received
            let response = Response(characteristic.value!)
            if let response = response {
                logger.a("\(response.description) received")
                
                if response.status == .success {
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
                report?(.unsupportedResponse, "Unsupported response received: 0x\(characteristic.value!.hexString)")
            }
        }
    }
}
