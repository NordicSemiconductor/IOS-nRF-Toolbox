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

internal typealias Callback = (Void) -> Void
internal typealias ErrorCallback = (_ error:DFUError, _ withMessage:String) -> Void

@objc internal class LegacyDFUService : NSObject, CBPeripheralDelegate {
    static internal let UUID = CBUUID.init(string: "00001530-1212-EFDE-1523-785FEABCD123")
    
    static func matches(_ service:CBService) -> Bool {
        return service.uuid.isEqual(UUID)
    }
    
    /// The target DFU Peripheral
    var targetPeripheral : LegacyDFUPeripheral?

    /// The logger helper.
    fileprivate var logger:LoggerHelper
    /// The service object from CoreBluetooth used to initialize the DFUService instance.
    fileprivate let service:CBService
    fileprivate var dfuPacketCharacteristic:DFUPacket?
    fileprivate var dfuControlPointCharacteristic:DFUControlPoint?
    fileprivate var dfuVersionCharacteristic:DFUVersion?
    
    /// The version read from the DFU Version charactertistic. Nil, if such does not exist.
    fileprivate(set) var version:(major:Int, minor:Int)?
    fileprivate var paused = false
    fileprivate var aborted = false
    
    /// A temporary callback used to report end of an operation.
    fileprivate var success:Callback?
    /// A temporary callback used to report an operation error.
    fileprivate var report:ErrorCallback?
    /// A temporaty callback used to report progress status.
    fileprivate var progressDelegate:DFUProgressDelegate?
    
    // -- Properties stored when upload started in order to resume it --
    fileprivate var firmware:DFUFirmware?
    fileprivate var packetReceiptNotificationNumber:UInt16?
    // -- End --
    
    // MARK: - Initialization
    
    init(_ service:CBService, _ logger:LoggerHelper) {
        self.service = service
        self.logger = logger
        super.init()
    }
    
    // MARK: - Service API methods
    
    /**
    Discovers characteristics in the DFU Service. This method also reads the DFU Version characteristic if such found.
    */
    func discoverCharacteristics(onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
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
        // If DFU Version characteritsic returned a correct value...
        if let version = version {
            // The app with buttonless update always returns value 0x0100 (major: 0, minor: 1). Otherwise it's in DFU mode.
            // See the documentation for DFUServiceInitiator.forceDfu(:Bool) for details about supported versions.
            return version.major == 0 && version.minor == 1
        }
        
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
    func enableControlPoint(onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.enableNotifications(onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Triggers a switch to DFU Bootloader mode on the remote target by sending DFU Start command.
     
     - parameter report:  method called when an error occurred
     */
    func jumpToBootloaderMode(onError report:@escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.jumpToBootloader, onSuccess: nil, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     This methods sends the Start DFU command with the firmware type to the DFU Control Point characterristic,
     followed by the sizes of each firware component <softdevice, bootloader, application> (each as UInt32, Little Endian).
     
     - parameter type:    the type of the current firmware part
     - parameter size:    the sizes of firmware components in the current part
     - parameter success: a callback called when a response with status Success is received
     - parameter report:  a callback called when a response with an error status is received
     */
    func sendDfuStartWithFirmwareType(_ type:UInt8, andSize size:DFUFirmwareSize, onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
        if aborted {
            sendReset(onError: report)
            return
        }
        
        // 1. Sends the Start DFU command with the firmware type to DFU Control Point characteristic
        // 2. Sends firmware sizes to DFU Packet characteristic
        // 3. Receives response notification and calls onSuccess or onError
        dfuControlPointCharacteristic!.send(Request.startDfu(type: type), onSuccess: success) { (error, aMessage) in
            if error == DFUError.remoteInvalidState {
                self.targetPeripheral?.resetInvalidState()
                self.sendReset(onError: report)
                return
            }
            report(error, aMessage)
        }
        dfuPacketCharacteristic!.sendFirmwareSize(size)
    }
    
    /**
     This methods sends the old Start DFU command (without the firmware type) to the DFU Control Point characterristic,
     followed by the application size <application> (UInt32, Little Endian).
     
     - parameter size:    the sizes of firmware components in the current part
     - parameter success: a callback called when a response with status Success is received
     - parameter report:  a callback called when a response with an error status is received
     */
    func sendStartDfuWithFirmwareSize(_ size:DFUFirmwareSize, onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
        if aborted {
            sendReset(onError: report)
            return
        }
        
        // 1. Sends the Start DFU command with the firmware type to the DFU Control Point characteristic
        // 2. Sends firmware sizes to the DFU Packet characteristic
        // 3. Receives response notification and calls onSuccess or onError
        dfuControlPointCharacteristic!.send(Request.startDfu_v1, onSuccess: success, onError: report)
        dfuPacketCharacteristic!.sendFirmwareSize_v1(size)
    }
    
    /**
     This method sends the Init Packet with additional firmware metadata to the target DFU device.
     The Init Packet is required since Bootloader v0.5 (SDK 7.0.0), when it has been extended with 
     firmware verification data, like IDs of supported softdevices, device type and revision, or application version.
     The extended Init Packet may also contain a hash of the firmware (since DFU from SDK 9.0.0).
     Before Init Packet became required it could have contained only 2-byte CRC of the firmware.
     
     - parameter data:    the Init Packet data
     - parameter success: a callback called when a response with status Success is received
     - parameter report:  a callback called when a response with an error status is received
     */
    func sendInitPacket(_ data:Data, onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
        if aborted {
            sendReset(onError: report)
            return
        }
        
        // The procedure of sending the Init Packet has changed the same time the DFU Version characterstic was introduced.
        // Before it was not required, and could contain only CRC of the firmware (2 bytes).
        // Since DFU Bootloader version 0.5 (SDK 7.0.0) it is required and has been extended. Must be at least 14 bytes:
        // Device Type (2), Device Revision (2), Application Version (4), SD array length (2), at least one SD or 0xFEFF (2), CRC or hash (2+)
        // For more details, see:
        // http://infocenter.nordicsemi.com/topic/com.nordic.infocenter.sdk5.v11.0.0/bledfu_example_init.html?cp=4_0_0_4_2_1_1_3
        // (or another version of this page, matching your DFU version)
        
        if version != nil {
            if data.count < 14 {
                // Init packet validation would have failed. We can safely abort here.
                report(DFUError.extendedInitPacketRequired, "Extended init packet required. Old one found instead.")
                return
            }
            // Since DFU v0.5, the Extended Init Packet may contain more than 20 bytes.
            // Therefore, there are 2 commands to the DFU Control Point required: one before we start sending init packet,
            // and another one the whole init packet is sent. After sending the second packet a notification will be received
            dfuControlPointCharacteristic!.send(Request.initDfuParameters(req: InitDfuParametersRequest.receiveInitPacket), onSuccess: nil, onError: report)
            dfuPacketCharacteristic!.sendInitPacket(data)
            dfuControlPointCharacteristic!.send(Request.initDfuParameters(req: InitDfuParametersRequest.initPacketComplete), onSuccess: success,
                onError: {
                    error, message in
                    if error == DFUError.remoteOperationFailed {
                        // Init packet validation failed. The device type, revision, app version or Softdevice version 
                        // does not match values specified in the Init packet.
                        report(error, "Operation failed. Ensure the firmware targets that device type and version.")
                    } else {
                        report(error, message)
                    }
            })
        } else {
            // Before that, the Init Packet could have contained only the 2-bytes CRC and was transfered in a single packet.
            // There was a single command sent to the DFU Control Point (Op Code = 2), followed by the Init Packet transfer
            // to the DFU Packet characteristic. After receiving this packet the DFU target was sending a notification with status.
            if data.count == 2 {
                dfuControlPointCharacteristic!.send(Request.initDfuParameters_v1, onSuccess: success, onError: report)
                dfuPacketCharacteristic!.sendInitPacket(data)
            } else {
                // After sending the Extended Init Packet, the DFU would fail on CRC validation eventually. 
                
                // NOTE!
                // We can do 2 thing: abort, with an error:
                report(DFUError.initPacketRequired, "Init packet with 2-byte CRC supported. Extended init packet found.")
                // ..or ignore it and do not send any init packet (not safe!):
                // success()
            }
        }
    }
    
    /**
     Sends Packet Receipt Notification Request command with given value.
     The DFU target will send Packet Receipt Notifications every time it receives given number of packets
     to synchronize the iDevice with the bootloader. The higher number is set, the faster the transmission
     may be, but too high values may also cause a buffer overflow error (the app may write
     packets to the outgoing queue then much faster then they are actually delivered). The
     Packet Receipt Notification procedure has been introduced to empty the outgoing buffer.
     Setting number to 0 will disable PRNs.
     
     - parameter number:  number of packets of firmware data to be received by the DFU target before
     sending a new Packet Receipt Notification.
     - parameter success: a callback called when a response with status Success is received
     - parameter report:  a callback called when a response with an error status is received
     */
    func sendPacketReceiptNotificationRequest(_ number:UInt16, onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.packetReceiptNotificationRequest(number: number), onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends the firmware data to the DFU target device.
     
     - parameter firmware: the firmware to be sent
     - parameter number:   number of packets of firmware data to be received by the DFU target before
     sending a new Packet Receipt Notification
     - parameter progressDelegate: a progress delagate that will be informed about transfer progress
     - parameter success:  a callback called when a response with status Success is received
     - parameter report:   a callback called when a response with an error status is received
     */
    func sendFirmware(_ firmware:DFUFirmware, withPacketReceiptNotificationNumber number:UInt16,
        onProgress progressDelegate:DFUProgressDelegate?, onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
            if aborted {
                sendReset(onError: report)
                return
            }
            
            // Store parameters in case the upload was paused and resumed
            self.firmware = firmware
            self.packetReceiptNotificationNumber = number
            self.progressDelegate = progressDelegate
            self.report = report
            
            // 1. Sends the Receive Firmware Image command to the DFU Control Point characteristic
            // 2. Sends firmware to the DFU Packet characteristic. If number > 0 it will receive Packet Receit Notifications
            //    every number packets.
            // 3. Receives response notification and calls onSuccess or onError
            dfuControlPointCharacteristic!.send(Request.receiveFirmwareImage,
                onSuccess: {
                    // Register callbacks for Packet Receipt Notifications/Responses
                    self.dfuControlPointCharacteristic!.waitUntilUploadComplete(
                        onSuccess: {
                            // Upload is completed, release the temporary parameters
                            self.firmware = nil
                            self.packetReceiptNotificationNumber = nil
                            self.progressDelegate = nil
                            self.report = nil
                            success()
                        },
                        onPacketReceiptNofitication: {
                            bytesReceived in
                            // Each time a PRN is received, send next bunch of packets
                            if !self.paused && !self.aborted {
                                let bytesSent = self.dfuPacketCharacteristic!.bytesSent
                                if bytesSent == bytesReceived {
                                    self.dfuPacketCharacteristic!.sendNext(number, packetsOf: firmware, andReportProgressTo: progressDelegate)
                                } else {
                                    // Target device deported invalid number of bytes received
                                    report(DFUError.bytesLost, "\(bytesSent) bytes were sent while \(bytesReceived) bytes were reported as received")
                                }
                            } else if self.aborted {
                                // Upload has been aborted. Reset the target device. It will disconnect automatically
                                self.sendReset(onError: report)
                            }
                        },
                        onError: {
                            error, message in
                            // Upload failed, release the temporary parameters
                            self.firmware = nil
                            self.packetReceiptNotificationNumber = nil
                            self.progressDelegate = nil
                            self.report = nil
                            report(error, message)
                        }
                    )
                    // ...and start sending firmware
                    if !self.paused && !self.aborted {
                        self.dfuPacketCharacteristic!.sendNext(number, packetsOf: firmware, andReportProgressTo: progressDelegate)
                    } else if self.aborted {
                        // Upload has been aborted. Reset the target device. It will disconnect automatically
                        self.sendReset(onError: report)
                    }
                },
                onError: report)
    }
    
    func pause() -> Bool {
        if !aborted {
            paused = true
        }
        return paused
    }
    
    func resume() -> Bool {
        if !aborted && paused && firmware != nil {
            paused = false
            // onSuccess and onError callbacks are still kept by dfuControlPointCharacteristic
            dfuPacketCharacteristic!.sendNext(packetReceiptNotificationNumber!, packetsOf: firmware!, andReportProgressTo: progressDelegate)
            return paused
        }
        paused = false
        return paused
    }
    
    func abort() -> Bool {
        aborted = true
        // When upload has been started and paused, we have to send the Reset command here as the device will 
        // not get a Packet Receipt Notification. If it hasn't been paused, the Reset command will be sent after receiving it, on line 270.
        if paused && firmware != nil {
            // Upload has been aborted. Reset the target device. It will disconnect automatically
            sendReset(onError: report!)
        }
        paused = false
        return aborted
    }
    
    /**
     Sends the Validate Firmware request to DFU Control Point characteristic.
     
     - parameter success: a callback called when a response with status Success is received
     - parameter report:  a callback called when a response with an error status is received
     */
    func sendValidateFirmwareRequest(onSuccess success: @escaping Callback, onError report:@escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.validateFirmware, onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends a command that will activate the new firmware and reset the DFU target device.
     Soon after calling this method the device should disconnect.
     
     - parameter report: a callback called when writing characteristic failed
     */
    func sendActivateAndResetRequest(onError report:@escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.activateAndReset, onSuccess: nil, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    // MARK: - Private service API methods
    
    /**
    Reads the DFU Version characteristic value. The characteristic must not be nil.
    
    - parameter success: the callback called when supported version number has been received
    - parameter report:  the error callback which is called in case of an error, or when obtained data are not supported
    */
    fileprivate func readDfuVersion(onSuccess success:@escaping Callback, onError report:@escaping ErrorCallback) {
        dfuVersionCharacteristic!.readVersion(
            onSuccess: {
                major, minor in
                self.version = (major, minor)
                success()
            },
            onError:report
        )
    }
    
    /**
     Sends a Reset command to the target DFU device. The device will disconnect automatically and restore the
     previous application (if DFU dual bank was used and application wasn't removed to make space for a new
     softdevice) or bootloader.
     
     - parameter report: a callback called when writing characteristic failed
     */
    fileprivate func sendReset(onError report:@escaping ErrorCallback) {
        dfuControlPointCharacteristic!.send(Request.reset, onSuccess: nil, onError: report)
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
            _report?(DFUError.serviceDiscoveryFailed, "Characteristics discovery failed")
        } else {
            logger.i("DFU characteristics discovered")
            
            // Find DFU characteristics
            for characteristic in service.characteristics! {
                if (DFUPacket.matches(characteristic)) {
                    dfuPacketCharacteristic = DFUPacket(characteristic, logger)
                } else if (DFUControlPoint.matches(characteristic)) {
                    dfuControlPointCharacteristic = DFUControlPoint(characteristic, logger)
                } else if (DFUVersion.matches(characteristic)) {
                    dfuVersionCharacteristic = DFUVersion(characteristic, logger)
                }
            }
            
            // Some validation
            if dfuControlPointCharacteristic == nil {
                logger.e("DFU Control Point characteristics not found")
                // DFU Control Point characteristic is required
                _report?(DFUError.deviceNotSupported, "DFU Control Point characteristic not found")
                return
            }
            if !dfuControlPointCharacteristic!.valid {
                logger.e("DFU Control Point characteristics must have Write and Notify properties")
                // DFU Control Point characteristic must have Write and Notify properties
                _report?(DFUError.deviceNotSupported, "DFU Control Point characteristic does not have the Write and Notify properties")
                return
            }
            
            // Note: DFU Packet characteristic is not required in the App mode.
            //       The mbed implementation of DFU Service doesn't have such.
            
            // Read DFU Version characteristic if such exists
            if self.dfuVersionCharacteristic != nil {
                if dfuVersionCharacteristic!.valid {
                    readDfuVersion(onSuccess: _success!, onError: _report!)
                } else {
                    version = nil
                    _report?(DFUError.readingVersionFailed, "DFU Version found, but does not have the Read property")
                }
            } else {
                // Else... proceed
                version = nil
                _success?()
            }
        }
    }
}
