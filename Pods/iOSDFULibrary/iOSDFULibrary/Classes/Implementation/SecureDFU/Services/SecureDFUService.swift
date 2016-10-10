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

internal typealias SDFUCallback = (_ responseData : Data?) -> Void
internal typealias SDFUErrorCallback = (_ error:SecureDFUError, _ withMessage:String) -> Void

@objc internal class SecureDFUService : NSObject, CBPeripheralDelegate {
    static internal let UUID = CBUUID.init(string: "FE59")
    
    static func matches(_ service:CBService) -> Bool {
        return service.uuid.isEqual(UUID)
    }
    
    /// The logger helper.
    fileprivate var logger:LoggerHelper
    /// The service object from CoreBluetooth used to initialize the SecureDFUService instance.
    fileprivate let service:CBService
    fileprivate var dfuPacketCharacteristic:SecureDFUPacket?
    fileprivate var dfuControlPointCharacteristic:SecureDFUControlPoint?

    fileprivate var paused = false
    fileprivate var aborted = false
    
    /// A temporary callback used to report end of an operation.
    fileprivate var success          : SDFUCallback?
    
    /// A temporary callback used to report an operation error.
    fileprivate var report           : SDFUErrorCallback?
    
    /// A temporaty callback used to report progress status.
    
    // -- Properties stored when upload started in order to resume it --
    fileprivate var progressDelegate : DFUProgressDelegate?
    fileprivate var firmware:DFUFirmware?
    fileprivate var packetReceiptNotificationNumber:UInt16?
    fileprivate var chunkRange:Range<Int>?
    // -- End --
    
    // MARK: - Initialization
    init(_ service:CBService, _ logger:LoggerHelper) {
        self.service = service
        self.logger = logger
        super.init()
    }
    
    // MARK: - Service API methods
    
    /**
    Discovers characteristics in the DFU Service.
    */
    func discoverCharacteristics(onSuccess success: @escaping SDFUCallback, onError report:@escaping SDFUErrorCallback) {
        // Save callbacks
        self.success = success
        self.report = report
        
        // Get the peripheral object
        let peripheral = service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        // Discover DFU characteristics
        logger.v("Discovering characteristics in DFU Service...")
        logger.d("peripheral.discoverCharacteristics(nil, forService:DFUService)")
        peripheral.discoverCharacteristics(nil, for:service)
    }
    
    /**
     This method tries to estimate whether the DFU target device is in Application mode which supports
     the buttonless jump to the DFU Bootloader.
     
     - returns: true, if it is for sure in the Application more, false, if definitely is not, nil if uknown
     */
    func isInApplicationMode() -> Bool? {        
        // The mbed implementation of DFU does not have DFU Packet characteristic in application mode
        if dfuPacketCharacteristic == nil {
            return true
        }
        
        // At last, count services. When only one service found - the DFU Service - we must be in the DFU mode already
        // (otherwise the device would be useless...)
        // Note: On iOS the Generic Access and Generic Attribute services (nor HID Service)
        //       are not returned during service discovery.
        let services = service.peripheral.services!
        if services.count == 1 {
            return false
        }
        // If there are more services than just DFU Service, the state is uncertain
        return nil
    }
    
    /**
     Enables notifications for DFU Control Point characteristic. Result it reported using callbacks.
     
     - parameter success: method called when notifications were enabled without a problem
     - parameter report:  method called when an error occurred
     */
    func enableControlPoint(onSuccess success: @escaping SDFUCallback, onError report:@escaping SDFUErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic?.enableNotifications(onSuccess: success, onError: report)
        }
    }
    
    /**
     Reads object info command
     */
    func readObjectInfoCommand(onSuccess successCallback: @escaping SDFUCallback, onError reportCallback:@escaping SDFUErrorCallback) {
        dfuControlPointCharacteristic?.send(SecureDFURequest.readObjectInfoCommand(), onSuccess: successCallback, onError: reportCallback)
    }
    
    /**
     Reads object info Data
     */
    func readObjectInfoData(onSuccess successCallback: @escaping SDFUCallback, onError reportCallback:@escaping SDFUErrorCallback) {
        dfuControlPointCharacteristic?.send(SecureDFURequest.readObjectInfoData(), onSuccess: successCallback, onError: reportCallback)
    }

    /**
     Reads extended error
     */
    func readError(onSuccess successCallback : @escaping SDFUCallback, onError reportCallback : @escaping SDFUErrorCallback) {
        self.logger.a("Sending read execute error command")
        dfuControlPointCharacteristic?.send(SecureDFURequest.readError(), onSuccess: { (responseData) in
                self.logger.a("Received Extended error data: \(responseData!)")
                successCallback(responseData)
            }, onError: { (anError, aMessage) in
                self.logger.e("Failed to read Extended with error: \(anError), and message: \(aMessage)")
                reportCallback(anError, aMessage)
        })
    }
    /**
     Create object data
     */
    func createObjectData(withLength aLength : UInt32, onSuccess successCallback : @escaping SDFUCallback, onError reportCallback:@escaping SDFUErrorCallback) {
        dfuControlPointCharacteristic?.send(SecureDFURequest.createData(size: aLength), onSuccess: successCallback, onError:reportCallback)
    }
    
    /**
     Create object command
     */
    func createObjectCommand(withLength aLength : UInt32, onSuccess successCallback : @escaping SDFUCallback, onError reportCallback:@escaping SDFUErrorCallback) {
        dfuControlPointCharacteristic?.send(SecureDFURequest.createCommand(size: aLength), onSuccess: successCallback, onError:reportCallback)
    }
    
    /**
     Calculate checksum
    */
    func calculateChecksumCommand(onSuccess successCallback : @escaping SDFUCallback, onError reportCallback: @escaping SDFUErrorCallback) {
        dfuControlPointCharacteristic?.send(SecureDFURequest.calculateChecksumCommand(), onSuccess: successCallback, onError: reportCallback)
    }
    
    /**
     Send execute command
    */
    func executeCommand(onSuccess successCallback : @escaping SDFUCallback, onError reportCallback: @escaping SDFUErrorCallback) {
        dfuControlPointCharacteristic?.send(SecureDFURequest.executeCommand(), onSuccess: successCallback, onError: reportCallback)
    }
    //MARK: - Packet commands
    /**
     Send init packet
    */
    func sendInitPacket(withdata packetData : Data){
        dfuPacketCharacteristic?.sendInitPacket(packetData)
    }

    func sendFirmwareChunk(_ chunkRange : Range<Int>, inFirmware aFirmware : DFUFirmware, andPacketReceiptCount aCount : UInt16, andProgressDelegate progressDelegate : DFUProgressDelegate, andCompletionHandler completionHandler : @escaping SDFUCallback, andErrorHandler errorHandler : @escaping SDFUErrorCallback) {

        //Those will be stored here in case of pause/resume
        self.success                            = completionHandler
        self.report                             = errorHandler
        self.firmware                           = aFirmware
        self.packetReceiptNotificationNumber    = aCount
        self.chunkRange                         = chunkRange
        self.progressDelegate                   = progressDelegate

        let successHandler : SDFUCallback = { (responseData) in
            self.dfuControlPointCharacteristic?.uploadFinished()
            completionHandler(nil)
        }

        self.dfuControlPointCharacteristic!.waitUntilUploadComplete(onSuccess: successHandler, onPacketReceiptNofitication: { (bytesReceived) in
                if !self.paused && !self.aborted {
                    self.dfuPacketCharacteristic?.sendData(withPRN: aCount, andRange: chunkRange, inFirmware: aFirmware, andProgressHandler: progressDelegate, andCompletion: successHandler)
                } else if self.aborted {
                    errorHandler(SecureDFUError.deviceDisconnected, "DFU operation aborted")
                }
            }
            , onError: errorHandler)

        //Reset counters before sending next chunk
        self.dfuPacketCharacteristic?.resetCounters()
        self.dfuPacketCharacteristic?.sendData(withPRN: aCount, andRange: chunkRange, inFirmware: aFirmware, andProgressHandler: progressDelegate, andCompletion: successHandler)
    }

    /**
     Set PRN
    */
    func setPacketReceiptNotificationValue(_ aValue : UInt16 = 0, onSuccess successCallback : @escaping SDFUCallback, onError reportCallback:@escaping SDFUErrorCallback) {
        self.packetReceiptNotificationNumber = aValue
        dfuControlPointCharacteristic?.send(SecureDFURequest.setPacketReceiptNotification(value: self.packetReceiptNotificationNumber!), onSuccess: successCallback, onError: reportCallback)
    }
    
    func pause() {
        if !aborted {
            paused = true
        }
    }
    
    func resume() {
        if !aborted {
            paused = false
            self.dfuPacketCharacteristic?.sendData(withPRN: self.packetReceiptNotificationNumber!, andRange: self.chunkRange!, inFirmware: self.firmware!, andProgressHandler: self.progressDelegate!, andCompletion: self.success!)
        }
    }
    
    func abort() {
        aborted = true
        paused = false
    }
    
    // MARK: - Peripheral Delegate callbacks

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Create local references to callback to release the global ones
        let _success = self.success
        let _report = self.report
        self.success = nil
        self.report = nil
        
        if error != nil {
            logger.e("Characteristics discovery failed")
            logger.e(error!)
            _report?(SecureDFUError.characteristicDiscoveryFailed, SecureDFUError.characteristicDiscoveryFailed.description)
        } else {
            logger.i("DFU characteristics discovered")
            
            // Find DFU characteristics
            for characteristic in service.characteristics! {
                if (SecureDFUPacket.matches(characteristic)) {
                    dfuPacketCharacteristic = SecureDFUPacket(characteristic, logger)
                } else if (SecureDFUControlPoint.matches(characteristic)) {
                    dfuControlPointCharacteristic = SecureDFUControlPoint(characteristic, logger)
                }
            }
            
            // Some validation
            if dfuControlPointCharacteristic == nil {
                logger.e("DFU Control Point characteristics not found")
                // DFU Control Point characteristic is required
                _report?(SecureDFUError.deviceNotSupported, SecureDFUError.deviceNotSupported.description)
                return
            }
            if !dfuControlPointCharacteristic!.valid {
                logger.e("DFU Control Point characteristics must have Write and Notify properties")
                // DFU Control Point characteristic must have Write and Notify properties
                _report?(SecureDFUError.deviceNotSupported, SecureDFUError.deviceNotSupported.description)
                return
            }
            
            // Note: DFU Packet characteristic is not required in the App mode.
            //       The mbed implementation of DFU Service doesn't have such.
            _success?(nil)
        }
    }
}
