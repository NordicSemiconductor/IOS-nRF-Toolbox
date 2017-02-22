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

internal protocol BaseDFUPeripheralAPI : class, DFUController {
    /**
     This method starts DFU process for given peripheral. If the peripheral is not connected it will call the connect() method,
     if it is connected, but services were not discovered before, it will try to discover services instead.
     If services were already discovered the DFU process will be started.
     */
    func start()
    
    /**
     Disconnects the target device.
     */
    func disconnect()
    
    /**
     This method breaks the cyclic reference and both DFUExecutor and DFUPeripheral may be released.
     */
    func destroy()
    
    /**
     This method should reset the device, preferably switching it to application mode.
     */
    func resetDevice()
}

internal class BaseDFUPeripheral<TD : BasePeripheralDelegate> : NSObject, BaseDFUPeripheralAPI, CBPeripheralDelegate, CBCentralManagerDelegate {
    /// Bluetooth Central Manager used to scan for the peripheral.
    internal let centralManager: CBCentralManager
    /// The DFU Target peripheral.
    internal var peripheral: CBPeripheral?
    /// The peripheral delegate.
    internal var delegate: TD?
    /// The optional logger delegate.
    internal let logger: LoggerHelper
    /// A list of services required to be found on the peripheral. May return nil - then all services will be discovered.
    internal var requiredServices: [CBUUID]? {
        // We have to find all services, not only those releated to DFU. This is required in case the target device
        // was created using SDK 6.0 or 6.1, where there was no DFU Version characteristic. In that case, this DFU library determines
        // whether to jump to bootloader, or proceed with DFU based on number of services found. We have to find all of them.
        // It is not necessary for newer firmwares (SDK 7+) or for Secure DFU where the code below could work.
        return nil
        
        /*
        // If the experimental feature was enabled
        if experimentalButtonlessServiceInSecureDfuEnabled {
            return [LegacyDFUService.UUID, SecureDFUService.UUID, SecureDFUService.ExperimentalButtonlessDfuUUID]
        }
        // By default only standard Secure and Legacy DFU services will be discovered
        return [LegacyDFUService.UUID, SecureDFUService.UUID]
        */
    }
    /// A flag indicating whether the eperimental Buttonless DFU Service in Secure DFU is supported
    internal let experimentalButtonlessServiceInSecureDfuEnabled: Bool
    /// Default error callback
    internal var defaultErrorCallback: ErrorCallback {
        return { (error, message) in self.delegate?.error(error, didOccurWithMessage: message) }
    }
    
    /// A flag set when upload has been aborted.
    fileprivate var aborted: Bool = false
    
    init(_ initiator: DFUServiceInitiator) {
        self.centralManager = initiator.centralManager
        self.logger = LoggerHelper(initiator.logger)
        self.experimentalButtonlessServiceInSecureDfuEnabled = initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu
        super.init()
        // Set the initial peripheral. It may be changed later (flashing App fw after first flashing SD/BL)
        self.peripheral = initiator.target
    }
    
    // MARK: - Base DFU Peripheral API
    
    func start() {
        aborted = false
        centralManager.delegate = self
        
        if peripheral!.state != .connected {
            connect()
        } else {
            let name = peripheral!.name ?? "Unknown device"
            logger.i("Connected to \(name)")
            
            let dfuService = findDfuService(in: peripheral!.services)
            if dfuService == nil {
                // DFU service has not been found, but it doesn't matter it's not there.
                // Perhaps the user's application didn't discover it. Let's discover DFU services.
                discoverServices()
            } else {
                // A DFU service was found, congratulations!
                logger.i("Services discovered")
                peripheralDidDiscoverDfuService(dfuService!)
            }
        }
    }
    
    func disconnect() {
        if peripheral!.state == .connected {
            logger.v("Disconnecting...")
        } else {
            logger.v("Cancelling connection...")
        }
        logger.d("centralManager.cancelPeripheralConnection(peripheral)")
        centralManager.cancelPeripheralConnection(peripheral!)
    }
    
    func destroy() {
        centralManager.delegate = nil
        peripheral?.delegate = nil
        delegate = nil
    }
    
    // MARK: - DFU Controller API
    
    func pause() -> Bool {
        // BaseDFUPeripheral does not support pausing or resuming
        return false
    }
    
    func resume() -> Bool {
        // BaseDFUPeripheral does not support pausing or resuming
        return false
    }
    
    func abort() -> Bool {
        aborted = true
        if peripheral?.state == .connecting {
            disconnect()
        }
        return true
    }
    
    // MARK: - Central Manager methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var stateAsString: String
        
        switch (central.state) {
        case .poweredOn:
            stateAsString = "Powered ON"
        case .poweredOff:
            stateAsString = "Powered OFF"
        case .resetting:
            stateAsString = "Resetting"
        case .unauthorized:
            stateAsString = "Unauthorized"
        case .unsupported:
            stateAsString = "Unsupported"
        case .unknown:
            stateAsString = "Unknown"
        }
        logger.d("[Callback] Central Manager did update state to: \(stateAsString)")
        if central.state != .poweredOn {
            // The device has been already disconnected if it was connected
            delegate?.error(.bluetoothDisabled, didOccurWithMessage: "Bluetooth adapter powered off")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        cleanUp()
        
        logger.d("[Callback] Central Manager did connect peripheral")
        let name = peripheral.name ?? "Unknown device"
        logger.i("Connected to \(name)")
        
        guard !aborted else {
            resetDevice()
            return
        }
        
        discoverServices()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        cleanUp()
        
        if let error = error {
            logger.d("[Callback] Central Manager did fail to connect peripheral")
            logger.e(error)
        } else {
            logger.d("[Callback] Central Manager did fail to connect peripheral without error")
        }
        logger.e("Device failed to connect")
        delegate?.peripheralDidFailToConnect()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        cleanUp()
        
        // We may expect an error with 
        // code = 7: "The specified device has disconnected from us." (graceful disconnect), or
        // code = 6: "The connection has timed out unexpectedly." (in case it disconnected before sending the ACK).
        if let error = error {
            let cbError = error as! CBError
            if cbError.code == CBError.connectionTimeout || cbError.code == CBError.peripheralDisconnected {
                logger.d("[Callback] Central Manager did disconnect peripheral")
                logger.i("Disconnected by the remote device")
                
                peripheralDidDisconnect()
            } else {
                logger.e("[Callback] Central Manager did disconnect peripheral with error: \(error.localizedDescription)")
                logger.i("Disconnected")
                
                logger.e(error)
                delegate?.peripheralDidDisconnect(withError: error)
            }
        } else {
            logger.d("[Callback] Central Manager did disconnect peripheral")
            logger.i("Disconnected")
            
            peripheralDidDisconnect()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // This empty method has to be here, otherwise the BaseCommonDFUPeripheral does not get this callback
        
        // Don't use central manager while DFU is in progress!
        print("DFU in progress, don't use this CentralManager instance!")
        central.stopScan()
    }
    
    // MARK: - Peripheral Delegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            logger.e("Services discovery failed")
            logger.e(error!)
            delegate?.error(.serviceDiscoveryFailed, didOccurWithMessage: "Services discovery failed")
            return
        }
        
        logger.i("Services discovered")
        
        guard !aborted else {
            resetDevice()
            return
        }
        
        // Search for DFU service
        guard let dfuService = findDfuService(in: peripheral.services) else {
            logger.e("DFU Service not found")
            // The device does not support DFU, nor buttonless jump
            delegate?.error(.deviceNotSupported, didOccurWithMessage: "DFU Service not found")
            return
        }
        // A DFU service was found, congratulations!
        peripheralDidDiscoverDfuService(dfuService)
    }
    
    // MARK: - Methods to be overriden in the final implementation
    
    /**
     Method called when a DFU service has been found.
     */
    func peripheralDidDiscoverDfuService(_ service: CBService) {
        fatalError("This method must be overriden")
    }
    
    /**
     Method called when the device got disconnected.
     */
    func peripheralDidDisconnect() {
        guard !aborted else {
            // The device has resetted. Notify user
            logger.w("Upload aborted")
            delegate?.peripheralDidDisconnectAfterAborting()
            return
        }
        
        // Notify the delegate about the disconnection.
        // Most probably an error occurred and will be reported to the user.
        delegate?.peripheralDidDisconnect()
    }
    
    /**
     This method should reset the device, preferably switching it to application mode.
     */
    func resetDevice() {
        if peripheral != nil && peripheral!.state != .disconnected {
            disconnect()
        } else {
            peripheralDidDisconnect()
        }
    }
    
    // MARK: - Private methods
    
    /**
     Looks for a DFU Service in given list of services.
     - returns: a DFUService type if a DFU service has been found, or nil if services are nil or the list
     does not contain any supported DFU Service.
     */
    private func findDfuService(in services:[CBService]?) -> CBService? {
        if let services = services {
            for service in services {
                // Skip the experimental Buttonless DFU Service if this feature wasn't enabled
                if experimentalButtonlessServiceInSecureDfuEnabled && SecureDFUService.matches(experimental: service) {
                    // The experimental Buttonless DFU Service for Secure DFU has been found
                    return service
                }
                if SecureDFUService.matches(service) {
                    // Secure DFU Service has been found
                    return service
                }
                if LegacyDFUService.matches(service) {
                    // Legacy DFU Service has been found
                    return service
                }
            }
        }
        return nil
    }
    
    /**
     Starts the service discovery.
     */
    private func discoverServices() {
        let services = requiredServices
        // Discover DFU service on the device to determine the DFU implementation.
        logger.v("Discovering services...")
        if services != nil {
            logger.d("peripheral.discoverServices(\(services!))")
        } else {
            logger.d("peripheral.discoverServices(nil)")
        }
        peripheral!.delegate = self
        peripheral!.discoverServices(services)
    }
    
    /**
     Connects to the peripheral and performs service discovery.
     */
    fileprivate func connect() {
        let name = peripheral!.name ?? "Unknown device"
        logger.v("Connecting to \(name)...")
        logger.d("centralManager.connect(peripheral, options: nil)")
        centralManager.connect(peripheral!, options: nil)
    }
    
    fileprivate func cleanUp() {
        // do nothing
    }
}

internal protocol DFUPeripheralAPI : BaseDFUPeripheralAPI {
    /**
     Checks whether the target device is in application mode and must be switched to the DFU mode.
     
     - parameter forceDfu: should the service assume the device is in DFU Bootloader mode when
     DFU Version characteristic does not exist and at least one other service has been found on the device.
     
     - returns: true if device needs buttonless jump to DFU Bootloader mode
     */
    func isInApplicationMode(_ forceDfu: Bool) -> Bool
    
    /**
     Scans for a next device to connect to. When device is found and selected, it connects to it.
     
     After updating the Softdevice the device may start advertising with an address incremented by 1.
     A BLE scan needs to be done to find this new peripheral (it's the same device, but as it
     advertises with a new address, from iOS point of view it completly different device).
     */
    func switchToNewPeripheralAndConnect()
    
    /**
     Returns whether the Init Packet is required by the target DFU device.
     
     - returns: true if init packet is required, false if not. Init packet is required
     since DFU Bootloader version 0.5 (SDK 7.0.0).
     */
    func isInitPacketRequired() -> Bool
    
    /// A flag set when a command to jump to DFU Bootloader has been sent.
    var jumpingToBootloader: Bool { get set }
    /// A flag set when a command to activate the new firmware and reset the device has been sent.
    var activating: Bool { get set }
    /// A flag set when the library should try again connecting to the device (it may be then in a correct state).
    var shouldReconnect: Bool { get set }
}

internal protocol DFUPeripheral : DFUPeripheralAPI {
    associatedtype DFUServiceType : DFUService
    
    /// Selector used to find the advertising peripheral in DFU Bootloader mode.
    var peripheralSelector: DFUPeripheralSelectorDelegate { get }
    
    /// The DFU Service instance. Not nil when found on the peripheral.
    var dfuService: DFUServiceType? { get set }
}

internal class BaseCommonDFUPeripheral<TD : DFUPeripheralDelegate, TS : DFUService> : BaseDFUPeripheral<TD>, DFUPeripheral {
    /// The peripheral selector instance specified in the initiator
    internal let peripheralSelector: DFUPeripheralSelectorDelegate
    
    internal typealias DFUServiceType = TS
    internal var dfuService: DFUServiceType?
    
    /// This flag must be set to true if switching to bootloader mode is expected after executing the next operation.
    /// The operation is expecter to reset the device. After the disconnect event is received the service will 
    /// try to connect back to the device, or scan for a new device matching specified selector, depending on
    /// `newAddressExpected` flag value.
    internal var jumpingToBootloader : Bool = false
    /// This flag must be set to true when the firmware upload is complete and device will restart and run the new fw
    /// after executing the next operation.
    internal var activating          : Bool = false
    /// This flag has the same behavior as `jumpingToBootloader`, but it's used when Invalid state error was received and
    /// a reset command will be executed. The service will reconnect to the same device.
    internal var shouldReconnect     : Bool = false
    /// This flag must be set to true if the device will advertise with a new device address after it resets.
    /// The service will scan and use specified peripheral selector in order to connect to the new peripheral.
    internal var newAddressExpected  : Bool = false
    
    override init(_ initiator: DFUServiceInitiator) {
        self.peripheralSelector = initiator.peripheralSelector
        super.init(initiator)
    }
    
    // MARK: - Base DFU Peripheral API
    
    override func peripheralDidDiscoverDfuService(_ service: CBService) {
        dfuService = DFUServiceType(service, logger)
        dfuService!.targetPeripheral = self
        dfuService!.discoverCharacteristics(
            onSuccess: { self.delegate?.peripheralDidBecomeReady() },
            onError: defaultErrorCallback
        )
    }
    
    override func peripheralDidDisconnect() {
        guard !aborted else {
            // The device has resetted. Notify user
            logger.w("Upload aborted")
            delegate?.peripheralDidDisconnectAfterAborting()
            return
        }
        
        if shouldReconnect {
            shouldReconnect = false
            // We need to reconnect to the device
            connect()
        } else if jumpingToBootloader {
            jumpingToBootloader = false
            if newAddressExpected {
                newAddressExpected = false
                // Scan for a new device and connect to it
                switchToNewPeripheralAndConnect()
            } else {
                // Connect again, hoping for DFU mode this time
                connect()
            }
        } else if activating {
            activating = false
            // This part of firmware has been successfully
            delegate?.peripheralDidDisconnectAfterFirmwarePartSent()
        } else {
            super.peripheralDidDisconnect()
        }
    }
    
    override func destroy() {
        super.destroy()
        cleanUp()
    }
    
    // MARK: - DFU Peripheral API
    
    func isInApplicationMode(_ forceDfu: Bool) -> Bool {
        // This method should be overridden if the final implementation supports buttonless jump
        return false
    }
    
    func isInitPacketRequired() -> Bool {
        // This method should be overridden if the final implementation requires Init Packet in the DFUFirmware
        return false
    }
    
    func switchToNewPeripheralAndConnect() {
        // Release the previous peripheral
        peripheral!.delegate = nil
        peripheral = nil
        cleanUp()
        
        guard !aborted else {
            resetDevice()
            return
        }
        
        logger.v("Scanning for the DFU Bootloader...")
        centralManager.scanForPeripherals(withServices: peripheralSelector.filterBy(hint: DFUServiceType.UUID))
    }
    
    // MARK: - Peripheral Delegate methods
    
    override func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Is this a device we are looking for?
        if peripheralSelector.select(peripheral, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI) {
            // Hurray!
            central.stopScan()
            
            if let name = peripheral.name {
                logger.i("DFU Bootloader found with name \(name)")
            } else {
                logger.i("DFU Bootloader found")
            }
            
            self.peripheral = peripheral
            connect()
        }
    }
    
    // MARK: - DFU Controller API
    
    override func pause() -> Bool {
        guard let dfuService = dfuService, !aborted else { return false }
        return dfuService.pause()
    }
    
    override func resume() -> Bool {
        guard let dfuService = dfuService, !aborted else { return false }
        return dfuService.resume() == false // resume() returns the 'paused' value
    }
    
    override func abort() -> Bool {
        aborted = true
        
        guard let dfuService = dfuService else {
            // DFU service has not yet been found.
            
            // Peripheral is nil when the switchToNewPeripheralAndConnect(_ selector:DFUPeripheralSelector) method was called
            // and the second peripheral has not been found yet.
            // Delegate is nil when peripheral was destroyed.
            if let delegate = delegate, peripheral == nil {
                logger.w("Upload aborted. Part 1 flashed sucessfully")
                centralManager.stopScan()
                delegate.peripheralDidDisconnectAfterAborting()
            }
            return true
        }
        
        logger.w("Aborting upload...")
        return dfuService.abort()
    }
    
    // MARK: - Private methods
    
    fileprivate override func cleanUp() {
        dfuService?.destroy()
        dfuService = nil
    }
}
