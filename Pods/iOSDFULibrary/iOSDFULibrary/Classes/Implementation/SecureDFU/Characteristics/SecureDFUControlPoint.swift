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

internal typealias SecureDFUProgressCallback = (bytesReceived:Int) -> Void

@available(iOS, introduced=0.1.9)
internal enum SecureDFUOpCode : UInt8 {
    case CreateObject               = 0x01
    case SetPRNValue                = 0x02
    case CalculateChecksum          = 0x03
    case Execute                    = 0x04
    case ReadError                  = 0x05
    case ReadObjectInfo             = 0x06
    case ResponseCode               = 0x60

    var code:UInt8 {
        return rawValue
    }
    
    var description: String{
        switch self {
            case .CreateObject:         return "Create Object"
            case .SetPRNValue:          return "Set PRN Value"
            case .CalculateChecksum:    return "Calculate Checksum"
            case .Execute:              return "Execute"
            case .ReadError:            return "Read Error"
            case .ReadObjectInfo:       return "Read Object Info"
            case .ResponseCode:         return "Response Code"
        }
    }
}

@available(iOS, introduced=0.1.9)
internal enum SecureDFUProcedureType : UInt8 {
    case Command = 0x01
    case Data    = 0x02
    
    var description: String{
        switch self{
            case .Command:  return "Command"
            case .Data:     return "Data"
        }
    }
}

@available(iOS, introduced=0.1.9)
internal enum SecureDFURequest {
    case CreateData(size : UInt32)
    case CreateCommand(size : UInt32)
    case ReadError()
    case ReadObjectInfoCommand()
    case ReadObjectInfoData()
    case SetPacketReceiptNotification(value : UInt16)
    case CalculateChecksumCommand()
    case ExecuteCommand()

    var data : NSData {
        switch self {
        case .CreateData(let aSize):
            //Split to UInt8
            let byteArray = 24.stride(through: 0, by: -8).map {
                UInt8(truncatingBitPattern: aSize >> UInt32($0))
            }
            //Size is converted to Little Endian (0123 -> 3210)
            let bytes:[UInt8] = [UInt8(SecureDFUOpCode.CreateObject.code), UInt8(SecureDFUProcedureType.Data.rawValue), byteArray[3], byteArray[2], byteArray[1], byteArray[0]]
            return NSData(bytes: bytes, length: bytes.count)
        case .CreateCommand(let aSize):
            //Split to UInt8
            let byteArray = 24.stride(through: 0, by: -8).map {
                UInt8(truncatingBitPattern: aSize >> UInt32($0))
            }
            //Size is converted to Little Endian (0123 -> 3210)
            let bytes:[UInt8] = [UInt8(SecureDFUOpCode.CreateObject.code), UInt8(SecureDFUProcedureType.Command.rawValue), byteArray[3], byteArray[2], byteArray[1], byteArray[0]]
            return NSData(bytes: bytes, length: bytes.count)
        case .ReadError():
            let bytes:[UInt8] = [SecureDFUOpCode.ReadError.code]
            return NSData(bytes: bytes, length: bytes.count)
        case .ReadObjectInfoCommand():
            let bytes:[UInt8] = [SecureDFUOpCode.ReadObjectInfo.code, SecureDFUProcedureType.Command.rawValue]
            return NSData(bytes: bytes, length: bytes.count)
        case .ReadObjectInfoData():
            let bytes:[UInt8] = [SecureDFUOpCode.ReadObjectInfo.code, SecureDFUProcedureType.Data.rawValue]
            return NSData(bytes: bytes, length: bytes.count)
        case .SetPacketReceiptNotification(let aSize):
            let byteArary:[UInt8] = [UInt8(aSize>>8), UInt8(aSize & 0x00FF)]
            let bytes:[UInt8] = [UInt8(SecureDFUOpCode.SetPRNValue.code), byteArary[1], byteArary[0]]
            return NSData(bytes: bytes, length: bytes.count)
        case .CalculateChecksumCommand():
            let byteArray:[UInt8] = [UInt8(SecureDFUOpCode.CalculateChecksum.code)]
            return NSData(bytes: byteArray, length: byteArray.count)
        case .ExecuteCommand():
            let byteArray:[UInt8] = [UInt8(SecureDFUOpCode.Execute.code)]
            return NSData(bytes: byteArray, length: byteArray.count)

        }
    }

    var description : String {
        switch self {
        case .CreateData(let size):
            return "Create object data with size : \(size)"
        case .CreateCommand(let size):
            return "Create object command with size: \(size)"
        case .ReadObjectInfoCommand():
            return "Read object information command"
        case .ReadObjectInfoData():
            return "Read object information data"
        case .SetPacketReceiptNotification(let size):
            return "Packet Receipt Notification command with value: \(size)"
        case .CalculateChecksumCommand():
            return "Calculate checksum for last object"
        case .ExecuteCommand():
            return "Execute last object command"
        case .ReadError():
            return "Read Extended error command"
        }
    }
}

internal enum SecureDFUResultCode : UInt8 {

    case InvalidCode           = 0x0
    case Success               = 0x01
    case OpCodeNotSupported    = 0x02
    case InvalidParameter      = 0x03
    case InsufficientResources = 0x04
    case InvalidObjcet         = 0x05
    case SignatureMismatch     = 0x06
    case UnsupportedType       = 0x07
    case OperationNotpermitted = 0x08
    case OperationFailed       = 0x0A
    case ExtendedError         = 0x0B
    
    var description:String {
        switch self {
            case .InvalidCode:           return "Invalid code"
            case .Success:               return "Success"
            case .OpCodeNotSupported:    return "Operation not supported"
            case .InvalidParameter:      return "Invalid parameter"
            case .InsufficientResources: return "Insufficient resources"
            case .InvalidObjcet:         return "Invalid object"
            case .SignatureMismatch:     return "Signature mismatch"
            case .OperationNotpermitted: return "Operation not permitted"
            case .UnsupportedType:       return "Unsupported type"
            case .OperationFailed:       return "Operation failed"
            case .ExtendedError:         return "Extended error"
        }
    }
    
    var code:UInt8 {
        return rawValue
    }
}

internal struct SecureDFUResponse {
    let opCode:SecureDFUOpCode?
    let requestOpCode:SecureDFUOpCode?
    let status:SecureDFUResultCode?
    let responseData : NSMutableData?
    
    init?(_ data:NSData) {
        var opCode          :UInt8          = 0
        var requestOpCode   :UInt8          = 0
        var status          :UInt8          = 0
        
        data.getBytes(&opCode, range: NSRange(location: 0, length: 1))
        data.getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        data.getBytes(&status, range: NSRange(location: 2, length: 1))
        self.opCode = SecureDFUOpCode(rawValue: opCode)
        self.requestOpCode = SecureDFUOpCode(rawValue: requestOpCode)
        self.status = SecureDFUResultCode(rawValue: status)
        self.responseData = NSMutableData(data: data.subdataWithRange(NSRange(location: 3, length: data.length - 3)))
        if self.opCode != SecureDFUOpCode.ResponseCode || self.requestOpCode == nil || self.status == nil {
            return nil
        }
    }

    var description:String {
        return "Response (Op Code = \(requestOpCode!.description), Status = \(status!.description))"
    }
}

internal struct SecureDFUPacketReceiptNotification {
    let opCode          : SecureDFUOpCode?
    let requestOpCode   : SecureDFUOpCode?
    let resultCode      : SecureDFUResultCode?
    let offset          : Int
    let crc             : UInt32

    init?(_ data:NSData) {

        var opCode         : UInt8 = 0
        var requestOpCode  : UInt8 = 0
        var resultCode     : UInt8 = 0

        data.getBytes(&opCode, range: NSRange(location: 0, length: 1))
        data.getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        data.getBytes(&resultCode, range: NSRange(location: 2, length: 1))

        self.opCode         = SecureDFUOpCode(rawValue: opCode)
        self.requestOpCode  = SecureDFUOpCode(rawValue: requestOpCode)
        self.resultCode     = SecureDFUResultCode(rawValue: resultCode)

        if self.opCode != SecureDFUOpCode.ResponseCode {
            print("wrong opcode \(self.opCode?.description)")
            return nil
        }
        if self.requestOpCode != SecureDFUOpCode.CalculateChecksum {
            print("wrong request code \(self.requestOpCode?.description)")
            return nil
        }
        if self.resultCode != SecureDFUResultCode.Success {
            print("Failed with eror: \(self.resultCode?.description)")
            return nil
        }

        var reportedOffsetLE:[UInt8] = [UInt8](count: 4, repeatedValue:0)
        data.getBytes(&reportedOffsetLE, range: NSRange(location: 3, length: 4))
        let offsetResult: UInt32 = reportedOffsetLE.reverse().reduce(UInt32(0)) {
            $0 << 0o10 + UInt32($1)
        }
        self.offset = Int(offsetResult)
        var reportedCRCLE:[UInt8] = [UInt8](count: 4, repeatedValue:0)
        data.getBytes(&reportedCRCLE, range: NSRange(location: 4, length: 4))
        let crcResult: UInt32 = reportedCRCLE.reverse().reduce(UInt32(0)) {
            $0 << 0o10 + UInt32($1)
        }
        self.crc = UInt32(crcResult)
    }
}

internal class SecureDFUControlPoint : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "8EC90001-F315-4F60-9FB8-838830DAEA50")
    static func matches(characteristic:CBCharacteristic) -> Bool {
        return characteristic.UUID.isEqual(UUID)
    }
    
    private var characteristic:CBCharacteristic
    private var logger:LoggerHelper
    
    private var success         : SDFUCallback?
    private var proceed         : SecureDFUProgressCallback?
    private var report          : SDFUErrorCallback?
    private var request         : SecureDFURequest?
    private var uploadStartTime : CFAbsoluteTime?

    var valid:Bool {
        return characteristic.properties.isSupersetOf([CBCharacteristicProperties.Write, CBCharacteristicProperties.Notify])
    }
    
    // MARK: - Initialization
    init(_ characteristic:CBCharacteristic, _ logger:LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    func getValue() -> NSData? {
        return characteristic.value
    }

    func uploadFinished() {
        self.proceed         = nil
    }

    // MARK: - Characteristic API methods
    
    /**
    Enables notifications for the DFU ControlPoint characteristics. Reports success or an error 
    using callbacks.
    
    - parameter success: method called when notifications were successfully enabled
    - parameter report:  method called in case of an error
    */
    func enableNotifications(onSuccess success:SDFUCallback?, onError report:SDFUErrorCallback?) {
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

    func send(request:SecureDFURequest, onSuccess success:SDFUCallback?, onError report:SDFUErrorCallback?) {

        // Save callbacks and parameter
        self.success = success
        self.report = report
        self.request = request
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        switch request {
            case .CreateData(let size):
                logger.a("Writing \(request.description), \(size/8) bytes")
                break
            case .CreateCommand(let size):
                logger.a("Writing \(request.description), \(size/8) bytes")
                break
            case .SetPacketReceiptNotification(let size):
                logger.a("Writing \(request.description), \(size) packets")
                break
            default:
                logger.a("Writing \(request.description)...")
                break
        }
        
        logger.v("Writing to characteristic \(SecureDFUControlPoint.UUID.UUIDString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), forCharacteristic: \(SecureDFUControlPoint.UUID.UUIDString), type: WithResponse)")
        peripheral.writeValue(request.data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }

    func waitUntilUploadComplete(onSuccess success:SDFUCallback?, onPacketReceiptNofitication proceed:SecureDFUProgressCallback?, onError report:SDFUErrorCallback?) {
        // Save callbacks. The proceed callback will be called periodically whenever a packet receipt notification is received. It resumes uploading.
        self.success         = success
        self.proceed         = proceed
        self.report          = report
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
            report?(error:SecureDFUError.EnablingControlPointFailed, withMessage:"Enabling notifications failed")
        } else {
            logger.v("Notifications enabled for \(SecureDFUControlPoint.UUID.UUIDString)")
            logger.a("DFU Control Point notifications enabled")
            success?(responseData: nil)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
        } else {
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {

        guard error == nil else {
            // This characteristic is never read, the error may only pop up when notification is received
            logger.e("Receiving notification failed")
            logger.e(error!)
            report?(error:SecureDFUError.ReceivingNotificationFailed, withMessage:SecureDFUError.ReceivingNotificationFailed.description)
            return
        }

        // During the upload we may get either a Packet Receipt Notification, or a Response with status code
        if proceed != nil {
            if let prn = SecureDFUPacketReceiptNotification(characteristic.value!) {
                    proceed!(bytesReceived: prn.offset)
                    return
            }
        }
        //Otherwise...
        proceed = nil

    
        logger.i("Notification received from \(characteristic.UUID.UUIDString), value (0x):\(characteristic.value!.hexString)")
        // Parse response received
        let response = SecureDFUResponse(characteristic.value!)
        if let response = response {
            logger.a("\(response.description) received")
            if response.status == SecureDFUResultCode.Success {
                switch response.requestOpCode! {
                case .ReadObjectInfo:
                    success?(responseData: response.responseData)
                    break
                case .CreateObject:
                    success?(responseData: response.responseData)
                    break
                case .SetPRNValue:
                    success?(responseData: response.responseData)
                    break
                case .CalculateChecksum:
                    success?(responseData: response.responseData)
                    break
                case .ReadError:
                    success?(responseData: response.responseData)
                    break
                case .Execute:
                    success?(responseData: nil)
                    break
                default:
                    success?(responseData: nil)
                    break
                }
            } else {
                logger.e("Error \(response.status?.description): \(response.status?.description)")
                report?(error: SecureDFUError(rawValue: Int(response.status!.rawValue))!, withMessage: response.status!.description)
            }
        } else {
            logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
            report?(error:SecureDFUError.UnsupportedResponse, withMessage:SecureDFUError.UnsupportedResponse.description)
        }
    }
}
