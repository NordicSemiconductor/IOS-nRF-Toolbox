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
    
    internal let centralManager   : CBCentralManager
    internal var targetIdentifier : UUID!
    internal var file             : DFUFirmware?
    
    internal var queue                 : DispatchQueue
    internal var delegateQueue         : DispatchQueue
    internal var progressDelegateQueue : DispatchQueue
    internal var loggerQueue           : DispatchQueue
    
    //MARK: - Public variables
    
    /**
     The service delegate is an object that will be notified about state changes of the DFU Service.
     Setting it is optional but recommended.
     */
    @objc public weak var delegate: DFUServiceDelegate?
    
    /**
     An optional progress delegate will be called only during upload. It notifies about current upload
     percentage and speed.
     */
    @objc public weak var progressDelegate: DFUProgressDelegate?
    
    /**
     The logger is an object that should print given messages to the user. It is optional.
     */
    @objc public weak var logger: LoggerDelegate?
    
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
    @objc public var peripheralSelector: DFUPeripheralSelectorDelegate

    /**
     The number of packets of firmware data to be received by the DFU target before sending
     a new Packet Receipt Notification.
     If this value is 0, the packet receipt notification will be disabled by the DFU target.
     Default value is 12.
     
     PRNs are no longer required on iOS 11 and MacOS 10.13 or newer, but make sure
     your device is able to be updated without. Old SDKs, before SDK 7 had very slow
     memory management and could not handle packets that fast. If your device
     is based on such SDK it is recommended to leave the default value.
     
     Disabling PRNs on iPhone 8 with iOS 11.1.2 increased the speed from 1.7 KB/s to 2.7 KB/s
     on DFU from SDK 14.1 where packet size is 20 bytes (higher MTU not supported yet).
     
     On older versions, higher values of PRN (~20+), or disabling it, may speed up
     the upload process, but also cause a buffer overflow and hang the Bluetooth adapter.
     Maximum verified values were 29 for iPhone 6 Plus or 22 for iPhone 7, both iOS 10.1.
     */
    @objc public var packetReceiptNotificationParameter: UInt16 = 12
    
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
    @objc public var forceDfu = false
    
    /**
     In SDK 14.0.0 a new feature was added to the Buttonless DFU for non-bonded devices which allows to send a unique name
     to the device before it is switched to bootloader mode. After jump, the bootloader will advertise with this name
     as the Complete Local Name making it easy to select proper device. In this case you don't have to override the default
     peripheral selector.
     
     Read more: http://infocenter.nordicsemi.com/topic/com.nordic.infocenter.sdk5.v14.0.0/service_dfu.html
     
     Setting this flag to false you will disable this feature. iOS DFU Library will not send the 0x02-[len]-[new name]
     command prior jumping and will rely on the DfuPeripheralSelectorDelegate just like it used to in previous SDK.
     
     This flag is ignored in Legacy DFU.
     
     **It is recommended to keep this flag set to true unless necessary.**
     
     For more information read: https://github.com/NordicSemiconductor/IOS-nRF-Connect/issues/16
     */
    @objc public var alternativeAdvertisingNameEnabled = true

    /**
     If `alternativeAdvertisingNameEnabled` is `true` then this specifies the alternative name to use. If nil (default)
     then a random name is generated.
     */
    @objc public var alternativeAdvertisingName: String? = nil
    
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
    @objc public var enableUnsafeExperimentalButtonlessServiceInSecureDfu = false

    /**
     UUIDs used during the DFU Process.
     This allows you to pass in Custom UUIDs for the DFU Service/Characteristics.
    */
    @objc public var uuidHelper: DFUUuidHelper

    /**
     Disable the ability for the DFU process to resume from where it was.
    */
    @objc public var disableResume: Bool = false

    //MARK: - Public API
    
    /**
     Creates the DFUServiceInitializer that will allow to send an update to the given peripheral.
     
     This constructor takes control over the central manager and peripheral objects.
     Their delegates will be set to internal library objects and will NOT be reverted to
     original objects, instead they will be set to nil when DFU is complete, aborted or
     has failed with an error. An app should restore the delegates (if needed) after
     receiving .completed or .aborted DFUState, or receiving an error.
     
     - important: This constructor has been deprecated in favor of `init(target: CBPeripheral)`,
     which does not take control over the give peripheral, and is using a copy instead.
     
     - parameter centralManager: Manager that will be used to connect to the peripheral
     - parameter target: The DFU target peripheral.
     
     - returns: The initiator instance.
     
     - seeAlso: peripheralSelector property - a selector used when scanning for a device in DFU Bootloader mode
     in case you want to update a Softdevice and Application from a single ZIP Distribution Packet.
     */
    @available(*, deprecated, message: "Use init(queue: DispatchQueue?) instead.")
    @objc public init(centralManager: CBCentralManager, target: CBPeripheral) {
        self.centralManager = centralManager
        // Just to be sure that manager is not scanning
        self.centralManager.stopScan()
        self.targetIdentifier = target.identifier
        // Default peripheral selector will choose the service UUID as a filter
        self.peripheralSelector = DFUPeripheralSelector()
        // Default UUID helper with standard set of UUIDs
        self.uuidHelper = DFUUuidHelper()

        self.queue = DispatchQueue.main
        self.delegateQueue = DispatchQueue.main
        self.progressDelegateQueue = DispatchQueue.main
        self.loggerQueue = DispatchQueue.main
        super.init()
    }
    
    /**
     Creates the DFUServiceInitializer that will allow to send an update to peripherals.
     
     - parameter queue: The dispatch queue to run BLE operations on.
     - parameter delegateQueue: The dispatch queue to invoke all delegate callbacks on.
     - parameter progressQueue: The dispatch queue to invoke all progress delegate callbacks on.
     - parameter loggerQueue: The dispatch queue to invoke all logger events on.
     
     - returns: The initiator instance.
     
     - version: Added in version 4.2 of the iOS DFU Library. Extended in 4.3 to allow setting delegate queues.
     - seeAlso: peripheralSelector property - a selector used when scanning for a device in DFU Bootloader mode
     in case you want to update a Softdevice and Application from a single ZIP Distribution Packet.
     */
    @objc public init(queue:         DispatchQueue? = nil,
                      delegateQueue: DispatchQueue = DispatchQueue.main,
                      progressQueue: DispatchQueue = DispatchQueue.main,
                      loggerQueue:   DispatchQueue = DispatchQueue.main) {
        // Create a new instance of CBCentralManager
        self.centralManager = CBCentralManager(delegate: nil, queue: queue)
        // Default peripheral selector will choose the service UUID as a filter
        self.peripheralSelector = DFUPeripheralSelector()
        // Default UUID helper with standard set of UUIDs
        self.uuidHelper = DFUUuidHelper()
        
        self.queue = queue ?? DispatchQueue.main
        self.delegateQueue = delegateQueue
        self.progressDelegateQueue = progressQueue
        self.loggerQueue = loggerQueue
        super.init()
    }
    
    /**
     Sets the file with the firmware. The file must be specified before calling
     `start(...)` method.
     
     - parameter file: The firmware wrapper object.
     
     - returns: The initiator instance to allow chain use.
     */
    @objc public func with(firmware file: DFUFirmware) -> DFUServiceInitiator {
        self.file = file
        return self
    }
    
    /**
     Starts sending the specified firmware to the DFU target specified in `init(centralManager:target)`.
     When started, the service will automatically connect to the target, switch to DFU Bootloader mode
     (if necessary), and send all the content of the specified firmware file in one or two connections.
     Two connections will be used if a ZIP file contains a Soft Device and/or Bootloader and an Application.
     First the Soft Device and/or Bootloader will be transferred, then the service will disconnect, reconnect
     to the (new) Bootloader again and send the Application (unless the target supports receiving all files
     in a single connection). The peripheral will NOT be reconnected after the DFU is completed, aborted
     or has failed.
     
     The current version of the DFU Bootloader, due to memory limitations, may receive together only
     a Softdevice and Bootloader.
     
     - important: Use `start(target: CBPeripheral)` instead.
     
     - returns: A DFUServiceController object that can be used to control the DFU operation,
     or nil, if the file was not set, or the target peripheral was not set.
     */
    @available(*, deprecated, message: "Use start(target: CBPeripheral) instead.")
    @objc public func start() -> DFUServiceController? {
        // The firmware file must be specified before calling `start()`.
        if file == nil {
            delegate?.dfuError(.fileNotSpecified, didOccurWithMessage: "Firmware not specified")
            return nil
        }
        
        // Make sure the target was set by the deprecated init.
        guard let _ = targetIdentifier else {
            delegate?.dfuError(.failedToConnect, didOccurWithMessage: "Target not specified: use start(target) instead")
            return nil
        }
        
        let controller = DFUServiceController()
        let selector   = DFUServiceSelector(initiator: self, controller: controller)
        controller.executor = selector
        selector.start()
        
        return controller
    }
    
    /**
     Starts sending the specified firmware to the given DFU target.
     When started, the service will automatically connect to the target, switch to DFU Bootloader mode
     (if necessary), and send all the content of the specified firmware file in one or two connections.
     Two connections will be used if a ZIP file contains a Soft Device and/or Bootloader and an Application.
     First the Soft Device and/or Bootloader will be transferred, then the service will disconnect, reconnect
     to the (new) Bootloader again and send the Application (unless the target supports receiving all files
     in a single connection). The peripheral will NOT be reconnected after the DFU is completed, aborted
     or has failed.
     
     This method does not take control over the peripheral.
     A new central manager is used, from which a copy of the peripheral is retrieved. Be warned,
     that the original peripheral delegate may receive a lot of calls, and it will restart during
     the process. The app should not send any data to DFU characteristics when DFU is in progress.
     
     The current version of the DFU Bootloader, due to memory limitations, may receive together only
     a Softdevice and Bootloader.
     
     - parameter target: The DFU target peripheral.
     
     - returns: A DFUServiceController object that can be used to control the DFU operation,
     or nil, if the file was not set, or the peripheral instance could not be retrieved.
     */
    @objc public func start(target: CBPeripheral) -> DFUServiceController? {
        return start(targetWithIdentifier: target.identifier)
    }
    
    /**
     Starts sending the specified firmware to the DFU target with given identifier.
     When started, the service will automatically connect to the target, switch to DFU Bootloader mode
     (if necessary), and send all the content of the specified firmware file in one or two connections.
     Two connections will be used if a ZIP file contains a Soft Device and/or Bootloader and an Application.
     First the Soft Device and/or Bootloader will be transferred, then the service will disconnect, reconnect
     to the (new) Bootloader again and send the Application (unless the target supports receiving all files
     in a single connection). The peripheral will NOT be reconnected after the DFU is completed, aborted
     or has failed.
     
     This method does not take control over the peripheral.
     A new central manager is used, from which a copy of the peripheral is retrieved. Be warned,
     that the original peripheral delegate may receive a lot of calls, and it will restart during
     the process. The app should not send any data to DFU characteristics when DFU is in progress.
     
     The current version of the DFU Bootloader, due to memory limitations, may receive together only
     a Softdevice and Bootloader.
     
     - parameter uuid: The UUID associated with the peer.
     
     - returns: A DFUServiceController object that can be used to control the DFU operation,
     or nil, if the file was not set, or the peripheral instance could not be retrieved.
     */
    @objc public func start(targetWithIdentifier uuid: UUID) -> DFUServiceController? {
        // The firmware file must be specified before calling `start(...)`.
        guard let _ = file else {
            delegate?.dfuError(.fileNotSpecified, didOccurWithMessage: "Firmware not specified")
            return nil
        }
        
        targetIdentifier = uuid
        
        let controller = DFUServiceController()
        let selector   = DFUServiceSelector(initiator: self, controller: controller)
        controller.executor = selector
        selector.start()
        
        return controller
    }
}
