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
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES LOSS OF USE, DATA, OR PROFITS OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import CoreBluetooth

@objc internal class LegacyDFUPeripheral: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    /// Bluetooth Central Manager used to scan for the peripheral.
    private let centralManager:CBCentralManager
    /// The DFU Target peripheral.
    private var peripheral:CBPeripheral?
    
    /// The optional logger delegate.
    private var logger:LoggerHelper
    /// The peripheral delegate.
    internal var delegate:DFUPeripheralDelegate?
    /// Selector used to find the advertising peripheral in DFU Bootloader mode.
    private var peripheralSelector:DFUPeripheralSelector?
    
    // MARK: - DFU properties
    
    /// The DFU Service instance. Not nil when found on the peripheral.
    private var dfuService:LegacyDFUService?
    /// A flag set when a command to jump to DFU Bootloader has been sent.
    private var jumpingToBootloader = false
    /// A flag set when a command to activate the new firmware and reset the device has been sent.
    private var activating = false
    /// A flag set when upload has been paused.
    private var paused = false
    /// A flag set when upload has been aborted.
    private var aborted = false
    /// A flag set when device is resetting
    private var resetting = false

    // MARK: - Initialization
    
    init(_ initiator:LegacyDFUServiceInitiator) {
        self.centralManager = initiator.centralManager
        self.peripheral = initiator.target
        self.logger = LoggerHelper(initiator.logger!)
        super.init()

        // self.peripheral.delegate = self // this is set when device got connected
        self.centralManager.delegate = self
    }
    
    // MARK: - Peripheral API
    
    /**
    Connects to the peripheral, performs service discovery and reads the DFU Version characteristic if such exists.
    When done, the `onDeviceReady()` callback is called. Errors are reported with `didErrorOccurred(error:withMessage)`.
    */
    func connect() {
        let name = peripheral!.name ?? "Unknown device"
        logger.v("Connecting to \(name)...")
        logger.d("centralManager.connectPeripheral(peripheral, options:nil)")
        centralManager.connectPeripheral(peripheral!, options: nil)
    }
    
    /**
     Disconnects the target device.
     */
    func disconnect() {
        logger.v("Disconnecting...")
        logger.d("centralManager.cancelPeripheralConnection(peripheral)")
        centralManager.cancelPeripheralConnection(peripheral!)
    }
    
    func pause() -> Bool {
        if !paused && dfuService != nil {
            paused = true
            dfuService!.pause()
            return true
        }
        return false
    }
    
    func resume() -> Bool {
        if paused && dfuService != nil {
            paused = false
            dfuService!.resume()
            return true
        }
        return false
    }
    
    func abort() {
        if dfuService != nil {
            logger.w("Upload aborted")
            aborted = true
            paused = false
            dfuService!.abort()
        }
    }
    
    /**
     Returns whether the Init Packet is required by the target DFU device.
     
     - returns: true if init packet is required, false if not. Init packet is required
     since DFU Bootloader version 0.5 (SDK 7.0.0).
     */
    func isInitPacketRequired() -> Bool {
        // Init packet has started being required the same time when the DFU Version
        // characteristic was introduced (SDK 7.0.0). It version exists, and we are not
        // in Application mode, then the Init Packet is required.
        
        if let version = dfuService!.version {
            // In the application mode we don't know whether init packet is required
            // as the app is indepenrent from the DFU Bootloader.
            let isInApplicationMode = version.major == 0 && version.minor == 1
            return !isInApplicationMode
        }
        return false
    }
    
    /**
     Enables notifications on DFU Control Point characteristic.
     */
    func enableControlPoint() {
        dfuService!.enableControlPoint(
            onSuccess: { self.delegate?.onControlPointEnabled() },
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }
    
    /**
     Calculates whether the target device is in application mode and must be switched to the DFU mode.
     
     - parameter forceDfu: should the service assume the device is in DFU Bootloader mode when 
     DFU Version characteristic does not exist and at least one other service has been found on the device.
     
     - returns: true if device needs buttonless jump to DFU Bootloader mode
     */
    func isInApplicationMode(forceDfu:Bool) -> Bool {
        let applicationMode = dfuService!.isInApplicationMode() ?? !forceDfu
        
        if applicationMode {
            logger.w("Application with buttonless update found")
        }
        
        return applicationMode
    }
    
    /**
     Switches target device to the DFU Bootloader mode.
     */
    func jumpToBootloader() {
        jumpingToBootloader = true
        dfuService!.jumpToBootloaderMode(
            // onSuccess the device gets disconnected and centralManager(_:didDisconnectPeripheral:error) will be called
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }
    
    /**
     Sends the DFU Start command with the specified firmware type to the DFU Control Point characteristic
     followed by firmware sizes (in bytes) to the DFU Packet characteristic. Then it waits for a response
     notification from the device. In case of a Success, it calls `delegate.onStartDfuSent()`.
     If the response has an error code NotSupported it means, that the target device does not support 
     updating Softdevice or Bootloader and the old Start DFU command needs to be used. The old command
     (without a type) allowed to send only an application firmware.
     
     - parameter type: the firmware type bitfield. See FIRMWARE_TYPE_* constants
     - parameter size: the size of all parts of the firmware
     */
    func sendStartDfuWithFirmwareType(type:UInt8, andSize size:DFUFirmwareSize) {
        dfuService!.sendDfuStartWithFirmwareType(type, andSize: size,
            onSuccess: { self.delegate?.onStartDfuSent() },
            onError: { error, message in
                if error == DFUError.RemoteNotSupported {
                    self.logger.w("DFU target does not support DFU v.2")
                    self.delegate?.onStartDfuWithTypeNotSupported()
                } else {
                    self.delegate?.didErrorOccur(error, withMessage: message)
                }
            }
        )
    }
    
    /**
     Sends the old Start DFU command, where there was no type byte. The old format allowed to send
     the application update only. Try this method if `sendStartDfuWithFirmwareType(_:andSize:)` 
     returned NotSupported and the firmware contains only the application.
     
     - parameter size: the size of all parts of the firmware, where size of softdevice and bootloader are 0
     */
    func sendStartDfuWithFirmwareSize(size:DFUFirmwareSize) {
        logger.v("Switching to DFU v.1")
        dfuService!.sendStartDfuWithFirmwareSize(size,
            onSuccess: { self.delegate?.onStartDfuSent() },
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }

    /**
     Sends the Init Packet with firmware metadata. When complete, the `delegate.onInitPacketSent()`
     callback is called.
     
     - parameter data: Init Packet data
     */
    func sendInitPacket(data:NSData) {
        dfuService!.sendInitPacket(data,
            onSuccess: { self.delegate?.onInitPacketSent() },
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }
    
    /**
     Sends the firmware to the DFU target device. Before that, it will send the desired number of
     packets to be received before sending a new Packet Receipt Notification.
     When the whole firmware is transferred the `delegate.onFirmwareSent()` callback is invoked.
     
     - parameter firmware: the firmware
     - parameter number: number of packets of firmware data to be received by the DFU target
     before sending a new Packet Receipt Notification. Set 0 to disable PRNs (not recommended)
     - parameter progressDelegate: the deleagate that will be informed about progress changes
     */
    func sendFirmware(firmware:DFUFirmware, withPacketReceiptNotificationNumber number:UInt16, andReportProgressTo progressDelegate:DFUProgressDelegate?) {
        dfuService!.sendPacketReceiptNotificationRequest(number,
            onSuccess: {
                // Now the service is ready to send the firmware
                self.dfuService!.sendFirmware(firmware, withPacketReceiptNotificationNumber: number,
                    onProgress: progressDelegate,
                    onSuccess: { self.delegate?.onFirmwareSent() },
                    onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
                )
            },
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }
    
    /**
     Sends the Validate Firmware request to DFU Control Point characteristic.
     On success, the `delegate.onFirmwareVerified()` method will be called.
     */
    func validateFirmware() {
        dfuService!.sendValidateFirmwareRequest(
            onSuccess: { self.delegate?.onFirmwareVerified() },
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }
    
    /**
     Sends a reset peripheral state
     */
    func resetInvalidState() {
        resetting = true
    }
    
    /**
     Sends the Activate and Reset command to the DFU Control Point characteristic.
     */
    func activateAndReset() {
        activating = true
        dfuService!.sendActivateAndResetRequest(
            // onSuccess the device gets disconnected and centralManager(_:didDisconnectPeripheral:error) will be called
            onError: { error, message in self.delegate?.didErrorOccur(error, withMessage: message) }
        )
    }
    
    /**
     Scans for a next device to connect to. When device is found and selected, it connects to it.
     
     After updating the Softdevice the device may start advertising with an address incremented by 1.
     A BLE scan needs to be done to find this new peripheral (it's the same device, but as it
     advertises with a new address, from iOS point of view it completly different device).
     
     - parameter selector: a selector used to select a device in DFU Bootloader mode
     */
    func switchToNewPeripheralAndConnect(selector:DFUPeripheralSelector) {
        // Release the previous peripheral
        self.peripheral!.delegate = nil
        self.peripheral = nil
        self.dfuService = nil
        
        self.peripheralSelector = selector
        logger.v("Scanning for the DFU Bootloader...")
        centralManager.delegate = self
        centralManager.scanForPeripheralsWithServices(selector.filterBy(), options: nil)
    }
    
    /**
     This method breaks the cyclic reference and both DFUExecutor and DFUPeripheral may be released.
     */
    func destroy() {
        centralManager.delegate = nil
        peripheral!.delegate = nil
        peripheral = nil
        delegate = nil
    }
    
    // MARK: - Central Manager methods
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        logCentralManagerState(central.state)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        cleanUp()
        
        logger.d("[Callback] Central Manager did connect peripheral")
        let name = peripheral.name ?? "Unknown device"
        logger.i("Connected to \(name)")
        
        // Discover all device services. In case there is no DFU Version characteristic the service
        // will determine whether to jump to the DFU Bootloader mode, or not, based on number of services.
        logger.v("Discovering services...")
        logger.d("peripheral.discoverServices(nil)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        cleanUp()
        
        if let error = error {
            logger.d("[Callback] Central Manager did fail to connect peripheral")
            logger.e(error)
        } else {
            logger.d("[Callback] Central Manager did fail to connect peripheral without error")
        }
        logger.e("Device failed to connect")
        delegate?.didDeviceFailToConnect()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // When device got disconnected due to a buttonless jump or a firmware activation, it is handled differently
        if jumpingToBootloader || activating || aborted || resetting {
            // This time we expect an error with code = 7: "The specified device has disconnected from us." (graceful disconnect)
            // or code = 6: "The connection has timed out unexpectedly." (in case it disconnected before sending the ACK).
            if error != nil {
                logger.d("[Callback] Central Manager did disconnect peripheral")
                if error!.code == 7 || error!.code == 6 {
                    logger.i("Disconnected by the remote device")
                    if resetting {
                        //We need to reconnect
                        self.delegate?.onDeviceReportedInvalidState()
                    }
                } else {
                    // This should never happen...
                    logger.e(error!)
                }
            } else {
                // This should never happen...
                logger.d("[Callback] Central Manager did disconnect peripheral without error")
            }
            
            if jumpingToBootloader {
                jumpingToBootloader = false
                // Connect again, hoping for DFU mode this time
                connect()
            } else if activating {
                activating = false
                // This part of firmware has been successfully
                delegate?.onTransferComplete()
            } else if aborted {
                // The device has reseted. Notify user
                delegate?.onAborted()
            }
            return
        }
        
        cleanUp()
        
        if let error = error {
            logger.d("[Callback] Central Manager did disconnect peripheral")
            logger.i("Disconnected")
            logger.e(error)
            delegate?.didDeviceDisconnectWithError(error)
        } else {
            logger.d("[Callback] Central Manager did disconnect peripheral without error")
            logger.i("Disconnected")
            delegate?.didDeviceDisconnect()
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if let peripheralSelector = peripheralSelector {
            // Is this a device we are looking for?
            if peripheralSelector.select(peripheral, advertisementData: advertisementData, RSSI: RSSI) {
                // Hurray!
                centralManager.stopScan()
                
                if let name = peripheral.name {
                    logger.i("DFU Bootloader found with name \(name)")
                } else {
                    logger.i("DFU Bootloader found")
                }
                
                self.peripheral = peripheral
                self.peripheralSelector = nil
                connect()
            }
        } else {
            // Don't use central manager while DFU is in progress!
            print("DFU in progress, don't use this CentralManager instance!")
            centralManager.stopScan()
        }
    }
    
    // MARK: - Peripheral Delegate methods
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error != nil {
            logger.e("Services discovery failed")
            logger.e(error!)
            delegate?.didErrorOccur(DFUError.ServiceDiscoveryFailed, withMessage: "Services discovery failed")
        } else {
            logger.i("Services discovered")
            
            // Find the DFU Service
            let services = peripheral.services!
            for service in services {
                if LegacyDFUService.matches(service) {
                    logger.v("DFU Service found")
                    
                    // DFU Service has been found. Discover characteristics...
                    dfuService = LegacyDFUService(service, logger)
                    dfuService?.targetPeripheral = self
                    dfuService!.discoverCharacteristics(
                        onSuccess: { () -> () in self.delegate?.onDeviceReady() },
                        onError: { (error, message) -> () in self.delegate?.didErrorOccur(error, withMessage: message) }
                    )
                }
            }
            
            if dfuService == nil {
                logger.e("DFU Service not found")
                // The device does not support DFU, nor buttonless jump
                delegate?.didErrorOccur(DFUError.DeviceNotSupported, withMessage: "DFU Service not found")
            }
        }
    }
    
    // MARK: - Private methods
    
    private func cleanUp() {
        dfuService = nil
    }
    
    private func logCentralManagerState(state:CBCentralManagerState) {
        var stateAsString:String
        
        switch (state) {
        case .PoweredOn:
            stateAsString = "Powered ON"
            break
            
        case .PoweredOff:
            stateAsString = "Powered OFF"
            break
            
        case .Resetting:
            stateAsString = "Resetting"
            break
            
        case .Unauthorized:
            stateAsString = "Unauthorized"
            break
            
        case .Unsupported:
            stateAsString = "Unsupported"
            break
            
        case .Unknown:
            stateAsString = "Unknown"
            break
        }
        logger.d("[Callback] Central Manager did update state to: \(stateAsString)")
    }
}