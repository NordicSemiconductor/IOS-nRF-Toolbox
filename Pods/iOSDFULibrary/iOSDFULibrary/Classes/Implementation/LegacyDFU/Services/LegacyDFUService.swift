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

@objc internal class LegacyDFUService : NSObject, CBPeripheralDelegate, DFUService {

    internal var targetPeripheral: DFUPeripheralAPI?
    internal var uuidHelper: DFUUuidHelper
    
    static func serviceUuid(from uuidHelper: DFUUuidHelper) -> CBUUID {
        return uuidHelper.legacyDFUService
    }
    
    /// The logger helper.
    private var logger: LoggerHelper
    /// The service object from CoreBluetooth used to initialize the DFUService instance.
    private let service                       : CBService
    private var dfuPacketCharacteristic       : DFUPacket?
    private var dfuControlPointCharacteristic : DFUControlPoint?
    private var dfuVersionCharacteristic      : DFUVersion?
    

    /// This method returns true if DFU Control Point characteristc has been discovered.
    /// A device without this characteristic is not supported and even can't be resetted by sending a Reset command.
    internal func supportsReset() -> Bool {
        return dfuControlPointCharacteristic != nil
    }
    
    /// The version read from the DFU Version charactertistic. Nil, if such does not exist.
    private(set) var version: (major: UInt8, minor: UInt8)?
    private var paused  = false
    private var aborted = false
    
    /// A temporary callback used to report end of an operation.
    private var success: Callback?
    /// A temporary callback used to report an operation error.
    private var report:  ErrorCallback?
    /// A temporaty callback used to report progress status.
    private var progressDelegate: DFUProgressDelegate?
    
    // -- Properties stored when upload started in order to resume it --
    private var firmware: DFUFirmware?
    private var packetReceiptNotificationNumber: UInt16 = 0
    // -- End --
    
    // MARK: - Initialization
    
    required init(_ service: CBService, _ logger: LoggerHelper, _ uuidHelper: DFUUuidHelper) {
        self.service = service
        self.logger = logger
        self.uuidHelper = uuidHelper
        
        super.init()
        self.logger.v("Legacy DFU Service found")
    }
    
    func destroy() {
        dfuPacketCharacteristic = nil
        dfuControlPointCharacteristic = nil
        dfuVersionCharacteristic = nil
        targetPeripheral = nil
        version = nil
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
            // onSuccess and onError callbacks are still kept by dfuControlPointCharacteristic
            dfuPacketCharacteristic!.sendNext(packetReceiptNotificationNumber, packetsOf: firmware!, andReportProgressTo: progressDelegate)
            return paused
        }
        paused = false
        return paused
    }
    
    func abort() -> Bool {
        aborted = true
        // When upload has been started and paused, we have to send the Reset command here as the device will
        // not get a Packet Receipt Notification. If it hasn't been paused, the Reset command will be sent after receiving it, on line 380.
        if paused && firmware != nil {
            let _report = report!
            firmware = nil
            success  = nil
            report   = nil
            progressDelegate = nil
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
        logger.d("peripheral.discoverCharacteristics(nil, for: \(uuidHelper.legacyDFUService.uuidString))")
        
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    /**
     This method tries to estimate whether the DFU target device is in Application mode which supports
     the buttonless jump to the DFU Bootloader.
     
     - returns: True, if it is for sure in the Application more, false, if definitely is not, nil if unknown.
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
     Returns whether the bootloader is expected to advertise with the same address on one incremented by 1.
     In the latter case the library needs to scan for a new advertising device and select it by filtering the adv packet,
     as device address is not available through iOS API.
     */
    var newAddressExpected: Bool {
        // See https://github.com/NordicSemiconductor/IOS-Pods-DFU-Library/issues/170 and
        // https://github.com/NordicSemiconductor/Android-DFU-Library/pull/45
        // The legacy bootloader will advertise with address +1 only in SDK 6.1. Future implementations
        // of legacy DFU will advertise directly with the same address no matter whether the device was
        // bonded or not. In SDK 6.1 there was no DFU Version characteristic.
        return version == nil
    }
    
    /**
     Enables notifications for DFU Control Point characteristic. Result it reported using callbacks.
     
     - parameter success: Method called when notifications were enabled without a problem.
     - parameter report:  Method called when an error occurred.
     */
    func enableControlPoint(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.enableNotifications(onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Triggers a switch to DFU Bootloader mode on the remote target by sending DFU Start command.
     
     - parameter report: Method called when an error occurred.
     */
    func jumpToBootloaderMode(onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.jumpToBootloader, onSuccess: nil, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     This methods sends the Start DFU command with the firmware type to the DFU Control Point characterristic,
     followed by the sizes of each firware component <softdevice, bootloader, application> (each as UInt32, Little Endian).
     
     - parameter type:    The type of the current firmware part.
     - parameter size:    The sizes of firmware components in the current part.
     - parameter success: A callback called when a response with status Success is received.
     - parameter report:  A callback called when a response with an error status is received.
     */
    func sendDfuStart(withFirmwareType type: UInt8, andSize size: DFUFirmwareSize, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        guard !aborted else {
            sendReset(onError: report)
            return
        }
        
        // It has been found that a bootloader from SDK 6.1 or older requires some time before the firmware can be sent in the following situation:
        // 1. DFU starts normally (the delay not required)
        // 2. DFU process interrupts by a link loss (Faraday cage used for testing)
        // 3. The iPhone reconnects and receives state = 2 (Invalid state) after sending app size - bootloader would like the old upload to be resumed,
        //    but new Start DFU sent instead (this is expected)
        // 4. The central sends Op Code = 06 (Reset) to reset the state
        // 5. The central reconnects and starts DFU again. Without the 1 sec delay below it would receive a response with status = 6 (Operation failed)
        //    after sending some firmware packets. Delay 1 sec seems to work while 600 ms was too short. The time seems to be required to prepare flash(?).
        let sendStartDfu = {
            // 1. Sends the Start DFU command with the firmware type to DFU Control Point characteristic
            // 2. Sends firmware sizes to DFU Packet characteristic
            // 3. Receives response notification and calls onSuccess or onError
            self.dfuControlPointCharacteristic!.send(Request.startDfu(type: type), onSuccess: success) { (error, aMessage) in
                if error == .remoteLegacyDFUInvalidState {
                    self.targetPeripheral!.shouldReconnect = true
                    self.sendReset(onError: report)
                    return
                }
                report(error, aMessage)
            }
            self.dfuPacketCharacteristic!.sendFirmwareSize(size)
        }
        if version != nil {
            // The legacy DFU bootloader from SDK 7.0+ does not require delay.
            sendStartDfu()
        } else {
            // DFU Version characteristic did not exist in SDK 6.1 or before. Delay is required as stated above.
            logger.d("wait(1000)")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: sendStartDfu)
        }
    }
    
    /**
     This methods sends the old Start DFU command (without the firmware type) to the DFU Control Point characterristic,
     followed by the application size <application> (UInt32, Little Endian).
     
     - parameter size:    The sizes of firmware components in the current part.
     - parameter success: A callback called when a response with status Success is received.
     - parameter report:  A callback called when a response with an error status is received.
     */
    func sendStartDfu(withFirmwareSize size: DFUFirmwareSize, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        guard !aborted else {
            sendReset(onError: report)
            return
        }
        
        // See comment in sendDfuStart(withFirmwareType:andSize:onSuccess:onError) above
        logger.d("wait(1000)")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            // 1. Sends the Start DFU command with the firmware type to the DFU Control Point characteristic
            // 2. Sends firmware sizes to the DFU Packet characteristic
            // 3. Receives response notification and calls onSuccess or onError
            self.dfuControlPointCharacteristic!.send(Request.startDfu_v1, onSuccess: success)  { (error, aMessage) in
                if error == .remoteLegacyDFUInvalidState {
                    self.targetPeripheral!.shouldReconnect = true
                    self.sendReset(onError: report)
                    return
                }
                report(error, aMessage)
            }
            self.dfuPacketCharacteristic!.sendFirmwareSize_v1(size)
        }
    }
    
    /**
     This method sends the Init Packet with additional firmware metadata to the target DFU device.
     The Init Packet is required since Bootloader v0.5 (SDK 7.0.0), when it has been extended with 
     firmware verification data, like IDs of supported softdevices, device type and revision, or application version.
     The extended Init Packet may also contain a hash of the firmware (since DFU from SDK 9.0.0).
     Before Init Packet became required it could have contained only 2-byte CRC of the firmware.
     
     - parameter data:    The Init Packet data.
     - parameter success: A callback called when a response with status Success is received.
     - parameter report:  A callback called when a response with an error status is received.
     */
    func sendInitPacket(_ data: Data, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        guard !aborted else {
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
                report(.extendedInitPacketRequired, "Extended init packet required. Old one found instead.")
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
                    if error == .remoteLegacyDFUOperationFailed {
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
                report(.initPacketRequired, "Init packet with 2-byte CRC supported. Extended init packet found.")
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
     
     - parameter prnValue: Number of packets of firmware data to be received by the DFU target before
     sending a new Packet Receipt Notification.
     - parameter success:  A callback called when a response with status Success is received.
     - parameter report:   A callback called when a response with an error status is received.
     */
    func sendPacketReceiptNotificationRequest(_ prnValue: UInt16, onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            packetReceiptNotificationNumber = prnValue
            dfuControlPointCharacteristic!.send(Request.packetReceiptNotificationRequest(number: prnValue), onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends the firmware data to the DFU target device.
     
     - parameter firmware: The firmware to be sent.
     - parameter delay:    If true, upload will be delayed by 1000ms.
     - parameter progress: A progress delagate that will be informed about transfer progress.
     - parameter success:  A callback called when a response with status Success is received.
     - parameter report:   A callback called when a response with an error status is received.
     */
    func sendFirmware(_ firmware: DFUFirmware, withDelay delay: Bool, andReportProgressTo progress: DFUProgressDelegate?,
                      onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        guard !aborted else {
            sendReset(onError: report)
            return
        }
        
        // Store parameters in case the upload was paused and resumed
        self.firmware         = firmware
        self.report           = report
        self.progressDelegate = progress
        
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
                        self.report   = nil
                        self.progressDelegate = nil
                        success()
                    },
                    onPacketReceiptNofitication: {
                        bytesReceived in
                        // This callback is called from SecureDFUControlPoint in 2 cases: when a PRN is received (bytesReceived contains number
                        // of bytes reported), or when the iOS reports the peripheralIsReady(toSendWriteWithoutResponse:) callback
                        // (bytesReceived is nil). If PRNs are enabled we ignore this second case as the PRNs are responsible for synchronization.
                        let peripheralIsReadyToSendWriteWithoutRequest = bytesReceived == nil
                        if self.packetReceiptNotificationNumber > 0 && peripheralIsReadyToSendWriteWithoutRequest {
                            return
                        }
                        
                        // Each time a PRN is received, send next bunch of packets
                        if !self.paused && !self.aborted {
                            let bytesSent = self.dfuPacketCharacteristic!.bytesSent
                            // Due to https://github.com/NordicSemiconductor/IOS-Pods-DFU-Library/issues/54 only 16 least significant bits are verified
                            if peripheralIsReadyToSendWriteWithoutRequest || (bytesSent & 0xFFFF) == (bytesReceived! & 0xFFFF) {
                                self.dfuPacketCharacteristic!.sendNext(self.packetReceiptNotificationNumber, packetsOf: firmware, andReportProgressTo: progress)
                            } else {
                                // Target device deported invalid number of bytes received
                                report(.bytesLost, "\(bytesSent) bytes were sent while \(bytesReceived!) bytes were reported as received")
                            }
                        } else if self.aborted {
                            // Upload has been aborted. Reset the target device. It will disconnect automatically
                            self.firmware = nil
                            self.report   = nil
                            self.progressDelegate = nil
                            self.sendReset(onError: report)
                        }
                    },
                    onError: {
                        error, message in
                        // Upload failed, release the temporary parameters
                        self.firmware = nil
                        self.report   = nil
                        self.progressDelegate = nil
                        report(error, message)
                    }
                )
                // ...and start sending firmware
                if !self.paused && !self.aborted {
                    let start = {
                        self.logger.a("Uploading firmware...")
                        self.logger.v("Sending firmware to DFU Packet characteristic...")
                        self.dfuPacketCharacteristic!.sendNext(self.packetReceiptNotificationNumber, packetsOf: firmware, andReportProgressTo: progress)
                    }
                    // On devices running SDK 6.0 or older a delay is required before the device is ready to receive data
                    if delay {
                        self.logger.d("wait(1000)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: start)
                    } else {
                        start()
                    }
                } else if self.aborted {
                    // Upload has been aborted. Reset the target device. It will disconnect automatically
                    self.firmware = nil
                    self.report   = nil
                    self.progressDelegate = nil
                    self.sendReset(onError: report)
                }
            },
            onError: report)
    }
    
    /**
     Sends the Validate Firmware request to DFU Control Point characteristic.
     
     - parameter success: A callback called when a response with status Success is received.
     - parameter report:  A callback called when a response with an error status is received.
     */
    func sendValidateFirmwareRequest(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.validateFirmware, onSuccess: success, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends a command that will activate the new firmware and reset the DFU target device.
     Soon after calling this method the device should disconnect.
     
     - parameter report: A callback called when writing characteristic failed.
     */
    func sendActivateAndResetRequest(onError report: @escaping ErrorCallback) {
        if !aborted {
            dfuControlPointCharacteristic!.send(Request.activateAndReset, onSuccess: nil, onError: report)
        } else {
            sendReset(onError: report)
        }
    }
    
    /**
     Sends a Reset command to the target DFU device. The device will disconnect automatically and restore the
     previous application (if DFU dual bank was used and application wasn't removed to make space for a new
     softdevice) or bootloader.
     
     - parameter report: A callback called when writing characteristic failed.
     */
    func sendReset(onError report: @escaping ErrorCallback) {
        dfuControlPointCharacteristic!.send(Request.reset, onSuccess: nil, onError: report)
    }
    
    // MARK: - Private service API methods
    
    /**
    Reads the DFU Version characteristic value. The characteristic must not be nil.
    
    - parameter success: The callback called when supported version number has been received.
    - parameter report:  The error callback which is called in case of an error, or when obtained data are not supported.
    */
    private func readDfuVersion(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback) {
        dfuVersionCharacteristic!.readVersion(
            onSuccess: {
                major, minor in
                self.version = (major, minor)
                success()
            },
            onError:report
        )
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Create local references to callback to release the global ones
        let _success = self.success
        let _report = self.report
        self.success = nil
        self.report = nil
        
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
                if characteristic.matches(uuid: uuidHelper.legacyDFUPacket) {
                    dfuPacketCharacteristic = DFUPacket(characteristic, logger)
                } else if characteristic.matches(uuid: uuidHelper.legacyDFUControlPoint) {
                    dfuControlPointCharacteristic = DFUControlPoint(characteristic, logger)
                } else if characteristic.matches(uuid: uuidHelper.legacyDFUVersion) {
                    dfuVersionCharacteristic = DFUVersion(characteristic, logger)
                }
            }
        }
        
        // Log what was found in case of an error
        if dfuPacketCharacteristic == nil {
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
        guard dfuControlPointCharacteristic!.valid else {
            logger.e("DFU Control Point characteristic must have Write and Notify properties")
            // DFU Control Point characteristic must have Write and Notify properties
            _report?(.deviceNotSupported, "DFU Control Point characteristic does not have the Write and Notify properties")
            return
        }
        
        // Note: DFU Packet characteristic is not required in the App mode.
        //       The mbed implementation of DFU Service doesn't have such.
        
        // Read DFU Version characteristic if such exists
        if self.dfuVersionCharacteristic != nil {
            guard dfuVersionCharacteristic!.valid else {
                version = nil
                _report?(.readingVersionFailed, "DFU Version found, but does not have the Read property")
                return
            }
            readDfuVersion(onSuccess: _success!, onError: _report!)
        } else {
            // Else... proceed
            version = nil
            _success?()
        }
    }
}
