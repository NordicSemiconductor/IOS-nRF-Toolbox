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

internal typealias SecureDFUProgressCallback = (_ bytesReceived:Int) -> Void

internal enum SecureDFUOpCode : UInt8 {
    case createObject               = 0x01
    case setPRNValue                = 0x02
    case calculateChecksum          = 0x03
    case execute                    = 0x04
    case readError                  = 0x05
    case readObjectInfo             = 0x06
    case responseCode               = 0x60

    var code:UInt8 {
        return rawValue
    }
    
    var description: String{
        switch self {
            case .createObject:         return "Create Object"
            case .setPRNValue:          return "Set PRN Value"
            case .calculateChecksum:    return "Calculate Checksum"
            case .execute:              return "Execute"
            case .readError:            return "Read Error"
            case .readObjectInfo:       return "Read Object Info"
            case .responseCode:         return "Response Code"
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
    case createData(size : UInt32)
    case createCommand(size : UInt32)
    case readError()
    case readObjectInfoCommand()
    case readObjectInfoData()
    case setPacketReceiptNotification(value : UInt16)
    case calculateChecksumCommand()
    case executeCommand()

    var data : Data {
        switch self {
        case .createData(let aSize):
            //Split to UInt8
            let byteArray = stride(from: 24, through: 0, by: -8).map {
                UInt8(truncatingBitPattern: aSize >> UInt32($0))
            }
            //Size is converted to Little Endian (0123 -> 3210)
            let bytes:[UInt8] = [UInt8(SecureDFUOpCode.createObject.code), UInt8(SecureDFUProcedureType.data.rawValue), byteArray[3], byteArray[2], byteArray[1], byteArray[0]]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .createCommand(let aSize):
            //Split to UInt8
            let byteArray = stride(from: 24, through: 0, by: -8).map {
                UInt8(truncatingBitPattern: aSize >> UInt32($0))
            }
            //Size is converted to Little Endian (0123 -> 3210)
            let bytes:[UInt8] = [UInt8(SecureDFUOpCode.createObject.code), UInt8(SecureDFUProcedureType.command.rawValue), byteArray[3], byteArray[2], byteArray[1], byteArray[0]]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .readError():
            let bytes:[UInt8] = [SecureDFUOpCode.readError.code]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .readObjectInfoCommand():
            let bytes:[UInt8] = [SecureDFUOpCode.readObjectInfo.code, SecureDFUProcedureType.command.rawValue]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .readObjectInfoData():
            let bytes:[UInt8] = [SecureDFUOpCode.readObjectInfo.code, SecureDFUProcedureType.data.rawValue]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .setPacketReceiptNotification(let aSize):
            let byteArary:[UInt8] = [UInt8(aSize>>8), UInt8(aSize & 0x00FF)]
            let bytes:[UInt8] = [UInt8(SecureDFUOpCode.setPRNValue.code), byteArary[1], byteArary[0]]
            return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        case .calculateChecksumCommand():
            let byteArray:[UInt8] = [UInt8(SecureDFUOpCode.calculateChecksum.code)]
            return Data(bytes: UnsafePointer<UInt8>(byteArray), count: byteArray.count)
        case .executeCommand():
            let byteArray:[UInt8] = [UInt8(SecureDFUOpCode.execute.code)]
            return Data(bytes: UnsafePointer<UInt8>(byteArray), count: byteArray.count)

        }
    }

    var description : String {
        switch self {
        case .createData(let size):
            return "Create object data with size : \(size)"
        case .createCommand(let size):
            return "Create object command with size: \(size)"
        case .readObjectInfoCommand():
            return "Read object information command"
        case .readObjectInfoData():
            return "Read object information data"
        case .setPacketReceiptNotification(let size):
            return "Packet Receipt Notification command with value: \(size)"
        case .calculateChecksumCommand():
            return "Calculate checksum for last object"
        case .executeCommand():
            return "Execute last object command"
        case .readError():
            return "Read Extended error command"
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
    
    var description:String {
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
    
    var code:UInt8 {
        return rawValue
    }
}

internal struct SecureDFUResponse {
    let opCode:SecureDFUOpCode?
    let requestOpCode:SecureDFUOpCode?
    let status:SecureDFUResultCode?
    var responseData : Data?
    
    init?(_ data:Data) {
        var opCode          :UInt8          = 0
        var requestOpCode   :UInt8          = 0
        var status          :UInt8          = 0
        
        (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
        (data as NSData).getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        (data as NSData).getBytes(&status, range: NSRange(location: 2, length: 1))
        self.opCode = SecureDFUOpCode(rawValue: opCode)
        self.requestOpCode = SecureDFUOpCode(rawValue: requestOpCode)
        self.status = SecureDFUResultCode(rawValue: status)
        if data.count > 3 {
            self.responseData = data.subdata(in: 3..<data.count)
        }else{
            self.responseData = nil
        }
        if self.opCode != SecureDFUOpCode.responseCode || self.requestOpCode == nil || self.status == nil {
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

    init?(_ data:Data) {

        var opCode         : UInt8 = 0
        var requestOpCode  : UInt8 = 0
        var resultCode     : UInt8 = 0

        (data as NSData).getBytes(&opCode, range: NSRange(location: 0, length: 1))
        (data as NSData).getBytes(&requestOpCode, range: NSRange(location: 1, length: 1))
        (data as NSData).getBytes(&resultCode, range: NSRange(location: 2, length: 1))

        self.opCode         = SecureDFUOpCode(rawValue: opCode)
        self.requestOpCode  = SecureDFUOpCode(rawValue: requestOpCode)
        self.resultCode     = SecureDFUResultCode(rawValue: resultCode)

        if self.opCode != SecureDFUOpCode.responseCode {
            print("wrong opcode \(self.opCode?.description)")
            return nil
        }
        if self.requestOpCode != SecureDFUOpCode.calculateChecksum {
            print("wrong request code \(self.requestOpCode?.description)")
            return nil
        }
        if self.resultCode != SecureDFUResultCode.success {
            print("Failed with eror: \(self.resultCode?.description)")
            return nil
        }

        var reportedOffsetLE:[UInt8] = [UInt8](repeating: 0, count: 4)
        (data as NSData).getBytes(&reportedOffsetLE, range: NSRange(location: 3, length: 4))
        let offsetResult: UInt32 = reportedOffsetLE.reversed().reduce(UInt32(0)) {
            $0 << 0o10 + UInt32($1)
        }
        self.offset = Int(offsetResult)
        var reportedCRCLE:[UInt8] = [UInt8](repeating: 0, count: 4)
        (data as NSData).getBytes(&reportedCRCLE, range: NSRange(location: 4, length: 4))
        let crcResult: UInt32 = reportedCRCLE.reversed().reduce(UInt32(0)) {
            $0 << 0o10 + UInt32($1)
        }
        self.crc = UInt32(crcResult)
    }
}

internal class SecureDFUControlPoint : NSObject, CBPeripheralDelegate {
    static let UUID = CBUUID(string: "8EC90001-F315-4F60-9FB8-838830DAEA50")
    static func matches(_ characteristic:CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    fileprivate var characteristic:CBCharacteristic
    fileprivate var logger:LoggerHelper
    
    fileprivate var success         : SDFUCallback?
    fileprivate var proceed         : SecureDFUProgressCallback?
    fileprivate var report          : SDFUErrorCallback?
    fileprivate var request         : SecureDFURequest?
    fileprivate var uploadStartTime : CFAbsoluteTime?

    var valid:Bool {
        return characteristic.properties.isSuperset(of: [CBCharacteristicProperties.write, CBCharacteristicProperties.notify])
    }
    
    // MARK: - Initialization
    init(_ characteristic:CBCharacteristic, _ logger:LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    func getValue() -> Data? {
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
        
        logger.v("Enabling notifiactions for \(DFUControlPoint.UUID.uuidString)...")
        logger.d("peripheral.setNotifyValue(true, forCharacteristic: \(DFUControlPoint.UUID.uuidString))")
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func send(_ request:SecureDFURequest, onSuccess success:SDFUCallback?, onError report:SDFUErrorCallback?) {

        // Save callbacks and parameter
        self.success = success
        self.report = report
        self.request = request
        
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        switch request {
            case .createData(let size):
                logger.a("Writing \(request.description), \(size/8) bytes")
                break
            case .createCommand(let size):
                logger.a("Writing \(request.description), \(size/8) bytes")
                break
            case .setPacketReceiptNotification(let size):
                logger.a("Writing \(request.description), \(size) packets")
                break
            default:
                logger.a("Writing \(request.description)...")
                break
        }
        
        logger.v("Writing to characteristic \(SecureDFUControlPoint.UUID.uuidString)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), forCharacteristic: \(SecureDFUControlPoint.UUID.uuidString), type: WithResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
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
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.e("Enabling notifications failed")
            logger.e(error!)
            report?(SecureDFUError.enablingControlPointFailed, "Enabling notifications failed")
        } else {
            logger.v("Notifications enabled for \(SecureDFUControlPoint.UUID.uuidString)")
            logger.a("DFU Control Point notifications enabled")
            success?(nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
        } else {
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard error == nil else {
            // This characteristic is never read, the error may only pop up when notification is received
            logger.e("Receiving notification failed")
            logger.e(error!)
            report?(SecureDFUError.receivingNotificationFailed, SecureDFUError.receivingNotificationFailed.description)
            return
        }

        // During the upload we may get either a Packet Receipt Notification, or a Response with status code
        if proceed != nil {
            if let prn = SecureDFUPacketReceiptNotification(characteristic.value!) {
                    proceed!(prn.offset)
                    return
            }
        }
        //Otherwise...
        proceed = nil

    
        logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x):\(characteristic.value!.hexString)")
        // Parse response received
        let response = SecureDFUResponse(characteristic.value!)
        if let response = response {
            logger.a("\(response.description) received")
            if response.status == SecureDFUResultCode.success {
                switch response.requestOpCode! {
                case .readObjectInfo:
                    success?(response.responseData)
                    break
                case .createObject:
                    success?(response.responseData)
                    break
                case .setPRNValue:
                    success?(response.responseData)
                    break
                case .calculateChecksum:
                    success?(response.responseData)
                    break
                case .readError:
                    success?(response.responseData)
                    break
                case .execute:
                    success?(nil)
                    break
                default:
                    success?(nil)
                    break
                }
            } else {
                logger.e("Error \(response.status?.description): \(response.status?.description)")
                report?(SecureDFUError(rawValue: Int(response.status!.rawValue))!, response.status!.description)
            }
        } else {
            logger.e("Unknown response received: 0x\(characteristic.value!.hexString)")
            report?(SecureDFUError.unsupportedResponse, SecureDFUError.unsupportedResponse.description)
        }
    }
}
