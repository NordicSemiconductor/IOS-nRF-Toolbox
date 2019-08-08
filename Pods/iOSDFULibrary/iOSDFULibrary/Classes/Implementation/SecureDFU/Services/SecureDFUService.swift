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

@objc internal class SecureDFUService : NSObject, CBPeripheralDelegate, DFUService {

    internal let queue: DispatchQueue
    internal var targetPeripheral: DFUPeripheralAPI?
    internal var uuidHelper: DFUUuidHelper
    
    static func serviceUuid(from uuidHelper: DFUUuidHelper) -> CBUUID {
        return uuidHelper.secureDFUService
    }
    
    /// The logger helper.
    private var logger: LoggerHelper
    /// The service object from CoreBluetooth used to initialize the SecureDFUService instance.
    private let service                       : CBService
    private var dfuPacketCharacteristic       : SecureDFUPacket?
    private var dfuControlPointCharacteristic : SecureDFUControlPoint?

    private var paused  = false
    private var aborted = false
    
    /// A temporary callback used to report end of an operation.
    private var success          : Callback?
    /// A temporary callback used to report an operation error.
    private var report           : ErrorCallback?
    /// A temporaty callback used to report progress status.
    private var progressDelegate : DFUProgressDelegate?
    private var progressQueue    : DispatchQueue?
    
    // -- Properties stored when upload started in order to resume it --
    private var firmware: DFUFirmware?
    private var packetReceiptNotificationNumber: UInt16?
    private var range: Range<Int>?
    // -- End --
    
    // MARK: - Initialization
    
    required init(_ service: CBService, _ logger: LoggerHelper, _ uuidHelper: DFUUuidHelper, _ queue: DispatchQueue) {
        self.service = service
        self.logger = logger
        self.uuidHelper = uuidHelper
        self.queue = queue

        super.init()
        self.logger.v("Secure DFU Service found")
    }
    
    func destroy() {
        dfuPacketCharacteristic = nil
        dfuControlPointCharacteristic = nil
        targetPeripheral = nil
    }
    
    // MARK: - Controler API methods
    
    func pause() -> Bool {
        if !aborted {
            paused = true
        }
        return paused
    }
    
    func resume() -> Bool {
        if !aborted && paused && firmware != nil {
            paused = false
            dfuPacketCharacteristic!.sendNext(packetReceiptNotificationNumber ?? 0, packetsFrom: range!, of: firmware!,
                                              andReportProgressTo: progressDelegate, on: progressQueue!,
                                              andCompletionTo: success!)
            return paused
        }
        paused = false
        return paused
    }
    
    func abort() -> Bool {
        aborted = true
        // When upload has been started and paused, we have to send the Reset command here as the device will
        // not get a Packet Receipt Notification. If it hasn't been paused, the Reset command will be sent after receiving it, on line 292.
        if paused && firmware != nil {
            let _report = report!
            firmware = nil
            range    = nil
            success  = nil
            report   = nil
            progressDelegate = nil
            progressQueue = nil
            // Upload has been aborted. Reset the target device. It will disconnect automatically
            sendReset(onError: _report)
        }
        paused = false
        return aborted
    }
    
    // MARK: - Service API methods
    
    /**
     Discovers characteristics in the DFU Service. Result it reported using callbacks.
     
     - parameter success: Method called when required DFU characteristics were discovered.
     - parameter report:  Method called when an error occurred.
    */
    func discoverCharacteristics(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        // Save callbacks
        self.success = success
        self.report  = report
        
        // Get the peripheral object
        let peripheral = service.peripheral
        
        // Set the peripheral delegate to self
        peripheral.delegate = self
        
        // Discover DFU characteristics
        logger.v("Discovering characteristics in DFU Service...")
        logger.d("peripheral.discoverCharacteristics(nil, for: \(uuidHelper.secureDFUService.uuidString))")
        
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    /**
     Enables notifications for DFU Control Point characteristic. Result it reported using callbacks.
     
     - parameter success: Method called when notifications were enabled without a problem.
     - parameter report:  Method called when an error occurred.
     */
    func enableControlPoint(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            // Support for Buttonless DFU Service
            if buttonlessDfuCharacteristic != nil {
                buttonlessDfuCharacteristic!.enable(onSuccess: success, onError: report)
                return
            }
            // End
            dfuControlPointCharacteristic!.enableNotifications(onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Reads Command Object Info. Result it reported using callbacks.
     
     - parameter response: Method called when the response was received.
     - parameter report:   Method called when an error occurred.
     */
    func readCommandObjectInfo(onReponse response: @escaping SecureDFUResponseCallback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(SecureDFURequest.readCommandObjectInfo, onResponse: response, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Reads object info Data. Result it reported using callbacks.
     
     - parameter response: Method called when the response was received.
     - parameter report:   Method called when an error occurred.
     */
    func readDataObjectInfo(onReponse response: @escaping SecureDFUResponseCallback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(SecureDFURequest.readDataObjectInfo, onResponse: response, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Creates object command. Result it reported using callbacks.
     
     - parameter length:  Exact size of the object.
     - parameter success: Method called when the object has been created.
     - parameter report:  Method called when an error occurred.
     
     */
    func createCommandObject(withLength length: UInt32, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(SecureDFURequest.createCommandObject(withSize: length), onSuccess: success, onError:report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Creates object data. Result it reported using callbacks.
     
     - parameter length:  Exact size of the object.
     - parameter success: Method called when the object has been created.
     - parameter report:  Method called when an error occurred.
     */
    func createDataObject(withLength length: UInt32, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(SecureDFURequest.createDataObject(withSize: length), onSuccess: success, onError:report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends a Packet Receipt Notification request with given value. Result it reported using callbacks.
     
     - parameter newValue: Packet Receipt Notification value (0 to disable PRNs).
     - parameter success:  Method called when the PRN value has been set.
     - parameter report:   Method called when an error occurred.
     */
    func setPacketReceiptNotificationValue(_ newValue: UInt16 = 0, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if packetReceiptNotificationNumber == newValue {
            success()
        } else {
            packetReceiptNotificationNumber = newValue
            dfuControlPointCharacteristic?.send(SecureDFURequest.setPacketReceiptNotification(value: newValue),
                onSuccess: {
                    if newValue > 0 {
                        self.logger.a("Packet Receipt Notif enabled (Op Code = 2, Value = \(newValue))")
                    } else {
                        self.logger.a("Packet Receipt Notif disabled (Op Code = 2, Value = 0)")
                    }
                    success()
                },
                onError: report
            )
        }
    }
    
    /**
     Sends Calculate checksum request. Result it reported using callbacks.
     
     - parameter response: Method called when the response was received.
     - parameter report:   Method called when an error occurred.
     */
    func calculateChecksumCommand(onSuccess response: @escaping SecureDFUResponseCallback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(SecureDFURequest.calculateChecksumCommand, onResponse: response, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends Execute command request. Result it reported using callbacks.
     
     - parameter success: Method called when the object was executed without an error.
     - parameter report:  Method called when an error occurred.
     */
    func executeCommand(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic?.send(SecureDFURequest.executeCommand, onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Disconnects from the device.
     
     - parameter report: A callback called when writing characteristic failed.
     */
    private func sendReset(onError report: @escaping ErrorCallback) {
        aborted = true
        // There is no command to reset a Secure DFU device. We can just disconnect
        targetPeripheral!.disconnect()
    }
    
    //MARK: - Packet commands
    
    /**
     Sends the init packet. This method is synchronous and will terminate when all data were written.
     The init data file should not have more than ~16 packets of data as the buffer overflow error may occur.
     
     - parameter packetData: Data to be sent as Init Packet.
     */
    func sendInitPacket(withdata packetData: Data){
        dfuPacketCharacteristic!.sendInitPacket(packetData)
    }

    /**
     Sends the next object of firmware. Result it reported using callbacks.
     
     - parameter range:            Given range of the firmware will be sent.
     - parameter firmware:         The firmware from with part is to be sent.
     - parameter progressDelegate: An optional progress delegate.
     - parameter queue:            The queue to dispatch progress events on.
     - parameter success:          Method called when the object was sent.
     - parameter report:           Method called when an error occurred.
     */
    func sendNextObject(from range: Range<Int>, of firmware: DFUFirmware,
                        andReportProgressTo progressDelegate: DFUProgressDelegate?, on queue: DispatchQueue,
                        onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        guard !aborted else {
            sendReset(onError: report)
            return
        }
        
        // Those will be stored here in case of pause/resume
        self.firmware         = firmware
        self.range            = range
        self.progressDelegate = progressDelegate
        self.progressQueue    = queue
        
        self.report = {
            error, message in
            self.firmware = nil
            self.range    = nil
            self.success  = nil
            self.report   = nil
            self.progressDelegate = nil
            self.progressQueue = nil
            report(error, message)
        }
        self.success = {
            self.firmware = nil
            self.range    = nil
            self.success  = nil
            self.report   = nil
            self.progressDelegate = nil
            self.progressQueue = nil
            self.dfuControlPointCharacteristic!.peripheralDidReceiveObject()
            success()
        } as Callback

        dfuControlPointCharacteristic!.waitUntilUploadComplete(onSuccess: self.success!, onPacketReceiptNofitication: { bytesReceived in
                // This callback is called from SecureDFUControlPoint in 2 cases: when a PRN is received (bytesReceived contains number
                // of bytes reported), or when the iOS reports the peripheralIsReady(toSendWriteWithoutResponse:) callback
                // (bytesReceived is nil). If PRNs are enabled we ignore this second case as the PRNs are responsible for synchronization.
                let peripheralIsReadyToSendWriteWithoutRequest = bytesReceived == nil
                if self.packetReceiptNotificationNumber ?? 0 > 0 && peripheralIsReadyToSendWriteWithoutRequest {
                    return
                }
            
                if !self.paused && !self.aborted {
                    let bytesSent = self.dfuPacketCharacteristic!.bytesSent + UInt32(range.lowerBound)
                    if peripheralIsReadyToSendWriteWithoutRequest || bytesSent == bytesReceived! {
                        self.dfuPacketCharacteristic!.sendNext(self.packetReceiptNotificationNumber ?? 0, packetsFrom: range, of: firmware,
                                                               andReportProgressTo: progressDelegate, on: queue,
                                                               andCompletionTo: self.success!)
                    } else {
                        // Target device deported invalid number of bytes received
                        report(.bytesLost, "\(bytesSent) bytes were sent while \(bytesReceived!) bytes were reported as received")
                    }
                } else if self.aborted {
                    self.firmware = nil
                    self.range    = nil
                    self.success  = nil
                    self.report   = nil
                    self.progressDelegate = nil
                    self.sendReset(onError: report)
                }
            }, onError: self.report!)
        
        // A new object is started, reset counters before sending the next object
        // It must be done even if the upload was paused, otherwise it would be resumed from a wrong place
        dfuPacketCharacteristic!.resetCounters()
        
        if !paused && !aborted {
            // ...and start sending firmware if
            dfuPacketCharacteristic!.sendNext(packetReceiptNotificationNumber ?? 0, packetsFrom: range, of: firmware,
                                              andReportProgressTo: progressDelegate, on: queue,
                                              andCompletionTo: self.success!)
        } else if aborted {
            self.firmware = nil
            self.range    = nil
            self.success  = nil
            self.report   = nil
            self.progressDelegate = nil
            sendReset(onError: report)
        }
    }
    
    // MARK: - Peripheral Delegate callbacks

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Create local references to callback to release the global ones
        let _success = self.success
        let _report  = self.report
        self.success = nil
        self.report  = nil
        
        guard error == nil else {
            logger.e("Characteristics discovery failed")
            logger.e(error!)
            _report?(.serviceDiscoveryFailed, "Characteristics discovery failed")
            return
        }

        logger.i("DFU characteristics discovered")
        
        // Find DFU characteristics
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.matches(uuid: uuidHelper.secureDFUPacket) {
                    dfuPacketCharacteristic = SecureDFUPacket(characteristic, logger)
                } else if characteristic.matches(uuid: uuidHelper.secureDFUControlPoint) {
                    dfuControlPointCharacteristic = SecureDFUControlPoint(characteristic, logger)
                }
                // Support for Buttonless DFU Service from SDK 12.x (as experimental).
                // SDK 13 added a new characteristic in Secure DFU Service with buttonless
                // feature without bond sharing (bootloader uses different device address).
                // SDK 14 added a new characteristic with buttonless service for bonded
                // devices with bond information sharing between app and the bootloader.
                else if uuidHelper.matchesButtonless(characteristic) {
                    buttonlessDfuCharacteristic = ButtonlessDFU(characteristic, logger)
                    buttonlessDfuCharacteristic?.uuidHelper = uuidHelper
                    _success?()
                    return
                }
                // End
            }
        }
        
        // Log what was found in case of an error
        if dfuPacketCharacteristic == nil || dfuControlPointCharacteristic == nil {
            if let characteristics = service.characteristics, characteristics.isEmpty == false {
                logger.d("The following characteristics were found:")
                characteristics.forEach { characteristic in
                    logger.d(" - \(characteristic.uuid.uuidString)")
                }
            } else {
                logger.d("No characteristics found in the service")
            }
            logger.d("Did you connect to the correct target? It might be that the previous services were cached: toggle Bluetooth from iOS settings to clear cache. Also, ensure the device contains the Service Changed characteristic")
        }
        
        // Some validation
        guard dfuControlPointCharacteristic != nil else {
            logger.e("DFU Control Point characteristic not found")
            // DFU Control Point characteristic is required
            _report?(.deviceNotSupported, "DFU Control Point characteristic not found")
            return
        }
        guard dfuPacketCharacteristic != nil else {
            logger.e("DFU Packet characteristic not found")
            // DFU Packet characteristic is required
            _report?(.deviceNotSupported, "DFU Packet characteristic not found")
            return
        }
        guard dfuControlPointCharacteristic!.valid else {
            logger.e("DFU Control Point characteristic must have Write and Notify properties")
            // DFU Control Point characteristic must have Write and Notify properties
            _report?(.deviceNotSupported, "DFU Control Point characteristic does not have the Write and Notify properties")
            return
        }
        guard dfuPacketCharacteristic!.valid else {
            logger.e("DFU Packet characteristic must have Write Without Response property")
            // DFU Packet characteristic must have Write Without Response property
            _report?(.deviceNotSupported, "DFU Packet characteristic must have Write Without Response property")
            return
        }
        
        _success?()
    }
    
    // MARK: - Support for Buttonless DFU Service
    
    /// The buttonless jump feature was experimental in SDK 12. It did not support passing bond information to the DFU bootloader,
    /// was not safe (possible DOS attack) and had bugs. This is the service UUID used by this service.
    private var buttonlessDfuCharacteristic: ButtonlessDFU?
    
    /**
     This method tries to estimate whether the DFU target device is in Application mode which supports
     the buttonless jump to the DFU Bootloader.
     
     - returns: True, if it is for sure in the Application more, false, if definitely is not, nil if unknown.
     */
    func isInApplicationMode() -> Bool? {
        // If the buttonless DFU characteristic is not nil it means that the device is in app mode.
        return buttonlessDfuCharacteristic != nil
    }
    
    /**
     Returns whether the bootloader is expected to advertise with the same address on one incremented by 1.
     In the latter case the library needs to scan for a new advertising device and select it by filtering the adv packet,
     as device address is not available through iOS API.
     */
    var newAddressExpected: Bool {
        // The bootloader will advertise with address +1 if the experimental Buttonless DFU Service from SDK 12.x
        // or Buttonless DFU service from SDK 13 were found.
        // The Buttonless DFU Service from SDK 14 supports bond sharing between app and the bootlaoder, thus the bootloader
        // will use the same address after jump and the connection will be encrypted.
        return buttonlessDfuCharacteristic?.newAddressExpected ?? false
    }
    
    /**
     Triggers a switch to DFU Bootloader mode on the remote target by sending DFU Start command.
     
     - parameter report: Method called when an error occurred.
     */
    func jumpToBootloaderMode(withAlternativeAdvertisingName name: String?, onError report: @escaping ErrorCallback) {
        if !aborted {
            func enterBootloader() {
                self.buttonlessDfuCharacteristic!.send(ButtonlessDFURequest.enterBootloader, onSuccess: nil, onError: report)
            }
            
            // If the device may support setting alternative advertising name in the bootloader mode, try it
            if let name = name, buttonlessDfuCharacteristic!.maySupportSettingName {
                logger.v("Trying setting bootloader name to \(name)")
                buttonlessDfuCharacteristic!.send(ButtonlessDFURequest.set(name: name), onSuccess: {
                    // Success. The buttonless service is from SDK 14.0+. The bootloader, after jumping to it, will advertise with this name.
                    self.targetPeripheral!.bootloaderName = name
                    self.logger.a("Bootloader name changed successfully")
                    enterBootloader()
                }, onError: {
                    error, message in
                    if error == .remoteButtonlessDFUOpCodeNotSupported {
                        // Setting name is not supported. Looks like it's buttonless service from SDK 13. We can't rely on bootloader's name.
                        self.logger.w("Setting bootloader name not supported")
                        enterBootloader()
                    } else {
                        // Something else got wrong
                        report(error, message)
                    }
                })
            } else {
                enterBootloader()
            }
        } else {
            sendReset(onError: report)
        }
    }
    
    // End
}
