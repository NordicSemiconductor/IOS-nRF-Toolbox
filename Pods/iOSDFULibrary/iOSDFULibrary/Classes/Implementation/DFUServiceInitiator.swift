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

/**
 The DFUServiceInitiator object should be used to send a firmware update to a remote BLE target compatible
 with the Nordic Semiconductor's DFU (Device Firmware Update).
 A `delegate`, `progressDelegate` and `logger` may be specified in order to receive status information.
 */
@objc public class DFUServiceInitiator : NSObject {
    
    //MARK: - Internal variables
    
    internal let centralManager : CBCentralManager
    internal let target         : CBPeripheral
    internal var file           : DFUFirmware?
    
    //MARK: - Public variables
    
    /**
     The service delegate is an object that will be notified about state changes of the DFU Service.
     Setting it is optional but recommended.
     */
    public weak var delegate: DFUServiceDelegate?
    
    /**
     An optional progress delegate will be called only during upload. It notifies about current upload
     percentage and speed.
     */
    public weak var progressDelegate: DFUProgressDelegate?
    
    /**
     The logger is an object that should print given messages to the user. It is optional.
     */
    public weak var logger: LoggerDelegate?
    
    /**
     The selector object is used when the device needs to disconnect and start advertising with a different address
     to avodi caching problems, for example after switching to the Bootloader mode, or during sending a firmware
     containing a Softdevice (or Softdevice and Bootloader) and the Application. 
     After flashing the first part (containing the Softdevice), the device restarts in the
     DFU Bootloader mode and may (since SDK 8.0.0) start advertising with an address incremented by 1.
     The peripheral specified in the `init` may no longer be used as there is no device advertising with its address.
     The DFU Service will scan for a new device and connect to the first device returned by the selector.
     
     The default selecter returns the first device with the required DFU Service UUID in the advertising packet
     (Secure or Legacy DFU Service UUID).
     
     Ignore this property if not updating Softdevice and Application from one ZIP file or your 
     */
    public var peripheralSelector: DFUPeripheralSelectorDelegate

    /**
     The number of packets of firmware data to be received by the DFU target before sending
     a new Packet Receipt Notification.
     If this value is 0, the packet receipt notification will be disabled by the DFU target.
     Default value is 12. Higher values (~20+), or disabling it, may speed up the upload process,
     but also cause a buffer overflow and hang the Bluetooth adapter.
     Maximum verified values were 29 for iPhone 6 Plus or 22 for iPhone 7, both iOS 10.1.
     */
    public var packetReceiptNotificationParameter: UInt16 = 12
    
    /**
     **Legacy DFU only.**
     
     Setting this property to true will prevent from jumping to the DFU Bootloader
     mode in case there is no DFU Version characteristic. Use it if the DFU operation can be handled by your
     device running in the application mode. If the DFU Version characteristic exists, the
     information whether to begin DFU operation, or jump to bootloader, is taken from the
     characteristic's value. The value returned equal to 0x0100 (read as: minor=1, major=0, or version 0.1)
     means that the device is in the application mode and buttonless jump to DFU Bootloader is supported.
     
     Currently, the following values of the DFU Version characteristic are supported:
     
     **No DFU Version characteristic** - one of the first implementations of DFU Service. The device
     may support only Application update (version from SDK 4.3.0), may support Soft Device, Bootloader
     and Application update but without buttonless jump to bootloader (SDK 6.0.0) or with
     buttonless jump (SDK 6.1.0).
     
     The DFU Library determines whether the device is in application mode or in DFU Bootloader mode
     by counting number of services: if no DFU Service found - device is in app mode and does not support
     buttonless jump, if the DFU Service is the only service found (except General Access and General Attribute
     services) - it assumes it is in DFU Bootloader mode and may start DFU immediately, if there is
     at least one service except DFU Service - the device is in application mode and supports buttonless
     jump. In the lase case, you want to perform DFU operation without jumping - call the setForceDfu(force:Bool)
     method with parameter equal to true.
     
     **0.1** - Device is in a mode that supports buttonless jump to the DFU Bootloader
     
     **0.5** - Device can handle DFU operation. Extended Init packet is required. Bond information is lost
     in the bootloader mode and after updating an app. Released in SDK 7.0.0.
     
     **0.6** - Bond information is kept in bootloader mode and may be kept after updating application
     (DFU Bootloader must be configured to preserve the bond information).
     
     **0.7** - The SHA-256 firmware hash is used in the Extended Init Packet instead of CRC-16.
     This feature is transparent for the DFU Service.
     
     **0.8** - The Extended Init Packet is signed using the private key. The bootloader, using the public key,
     is able to verify the content. Released in SDK 9.0.0 as experimental feature.
     Caution! The firmware type (Application, Bootloader, SoftDevice or SoftDevice+Bootloader) is not
     encrypted as it is not a part of the Extended Init Packet. A change in the protocol will be required
     to fix this issue.
     
     By default the DFU Library will try to switch the device to the DFU Bootloader mode if it finds
     more services then one (DFU Service). It assumes it is already in the bootloader mode
     if the only service found is the DFU Service. Setting the forceDfu to true (YES) will prevent from
     jumping in these both cases.
     */
    public var forceDfu = false
    
    /**
     Set this flag to true to enable experimental buttonless feature in Secure DFU. When the 
     experimental Buttonless DFU Service is found on a device, the service will use it to
     switch the device to the bootloader mode, connect to it in that mode and proceed with DFU.
     
     **Please, read the information below before setting it to true.**
     
     In the SDK 12.x the Buttonless DFU feature for Secure DFU was experimental.
     It is NOT recommended to use it: it was not properly tested, had implementation bugs 
     (e.g. https://devzone.nordicsemi.com/question/100609/sdk-12-bootloader-erased-after-programming/) and
     does not required encryption and therefore may lead to DOS attack (anyone can use it to switch the device
     to bootloader mode). However, as there is no other way to trigger bootloader mode on devices
     without a button, this DFU Library supports this service, but the feature must be explicitly enabled here.
     Be aware, that setting this flag to false will no protect your devices from this kind of attacks, as
     an attacker may use another app for that purpose. To be sure your device is secure remove this
     experimental service from your device.
     
     Spec:
     
     Buttonless DFU Service UUID: 8E400001-F315-4F60-9FB8-838830DAEA50
     
     Buttonless DFU characteristic UUID: 8E400001-F315-4F60-9FB8-838830DAEA50 (the same)
     
     Enter Bootloader Op Code: 0x01
     
     Correct return value: 0x20-01-01 , where:
       0x20 - Response Op Code
       0x01 - Request Code
       0x01 - Success
     The device should disconnect and restart in DFU mode after sending the notification.
     
     In SDK 13 this issue will be fixed by a proper implementation (bonding required,
     passing bond information to the bootloader, encryption, well tested). It is recommended to use this 
     new service when SDK 13 (or later) is out. TODO: fix the docs when SDK 13 is out.
     */
    public var enableUnsafeExperimentalButtonlessServiceInSecureDfu = false
    
    //MARK: - Public API
    
    /**
     Creates the DFUServiceInitializer that will allow to send an update to the given peripheral.
     The peripheral should be disconnected prior to calling start() method.
     The DFU service will automatically connect to the device, check if it has required DFU
     service (return a delegate callback if does not have such), jump to the DFU Bootloader mode
     if necessary and perform the DFU. Proper delegate methods will be called during the process.
     
     - parameter centralManager: manager that will be used to connect to the peripheral
     - parameter target: the DFU target peripheral
     
     - returns: the initiator instance
     
     - seeAlso: peripheralSelector property - a selector used when scanning for a device in DFU Bootloader mode
     in case you want to update a Softdevice and Application from a single ZIP Distribution Packet.
     */
    public init(centralManager: CBCentralManager, target: CBPeripheral) {
        self.centralManager = centralManager
        // Just to be sure that manager is not scanning
        self.centralManager.stopScan()
        self.target = target
        // Default peripheral selector will choose the service UUID as a filter
        self.peripheralSelector = DFUPeripheralSelector()
        super.init()
    }
    
    /**
     Sets the file with the firmware. The file must be specified before calling `start()` method,
     and must not be nil.
     
     - parameter file: The firmware wrapper object
     
     - returns: the initiator instance to allow chain use
     */
    public func with(firmware file: DFUFirmware) -> DFUServiceInitiator {
        self.file = file
        return self
    }
    
    /**
     Starts sending the specified firmware to the DFU target.
     When started, the service will automatically connect to the target, switch to DFU Bootloader mode
     (if necessary), and send all the content of the specified firmware file in one or two connections.
     Two connections will be used if a ZIP file contains a Soft Device and/or Bootloader and an Application.
     First the Soft Device and/or Bootloader will be transferred, then the service will disconnect, reconnect to
     the (new) Bootloader again and send the Application (unless the target supports receiving all files in a single
     connection).
     
     The current version of the DFU Bootloader, due to memory limitations, may receive together only a Softdevice and Bootloader.
     
     - returns: A DFUServiceController object that can be used to control the DFU operation.
     */
    public func start() -> DFUServiceController? {
        // The firmware file must be specified before calling `start()`
        if file == nil {
            delegate?.dfuError(.fileNotSpecified, didOccurWithMessage: "Firmare not specified")
            return nil
        }

        let controller = DFUServiceController()
        let selector   = DFUServiceSelector(initiator: self, controller: controller)
        controller.executor = selector
        selector.start()
        
        return controller
    }
}
