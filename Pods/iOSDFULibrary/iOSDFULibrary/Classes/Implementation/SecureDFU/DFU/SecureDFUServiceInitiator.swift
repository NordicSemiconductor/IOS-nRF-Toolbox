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
 A `delegate` and `logger` may be specified to be informed about the status.
 */
open class SecureDFUServiceInitiator : NSObject {
    internal let centralManager:CBCentralManager
    internal let target:CBPeripheral
    internal var file:DFUFirmware?
    
    /**
     The service delegate is an object that will be notified about state changes of the DFU Service.
     Setting it is optional but recommended.
     */
    open weak var delegate:DFUServiceDelegate?
    /**
     An optional progress delegate will be called only during upload. It notifies about current upload
     percentage and speed.
     */
    open weak var progressDelegate:DFUProgressDelegate?
    /**
     The logger is an object that should print given messages to the user. It is optional.
     */
    open weak var logger:LoggerDelegate?
    /**
     The selector object is used during sending a firmware containing a Softdevice (or Softdevice and Bootloader)
     and the Application. After flashing the first part (containing the Softdevice), the device restarts in the
     DFU Bootloader mode and may (since SDK 8.0.0) start advertising with an address incremented by 1.
     The peripheral specified in the `init` may no longer be used as there is no device advertising with its address.
     The DFU Service will scan for a new device and connect to the first device returned by the selector.
     
     The default selecter returns the first device with the DFU Service UUID in the advertising packet.
     
     Ignore this property if not updating Softdevice and Application from one ZIP file.
     */
    open var peripheralSelector:DFUPeripheralSelector
    
    /**
     The number of packets of firmware data to be received by the DFU target before sending
     a new Packet Receipt Notification (control point notification with Op Code = 7).
     If this value is 0, the packet receipt notification will be disabled by the DFU target.
     Default value is 12. Higher values, or disabling it, may speed up the upload process,
     but also cause a buffer overflow and hang the Bluetooth adapter.
     */
    open var packetReceiptNotificationParameter:UInt16 = 12
    
    /**
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
    open var forceDfu = false
    
    /**
     Creates the DFUServiceInitializer that will allow to send an update to the given peripheral.
     The peripheral should be disconnected prior to calling start() method.
     The DFU service will automatically connect to the device, check if it has required DFU
     service (return a delegate callback if does not have such), jump to the DFU Bootloader mode
     if necessary and perform the DFU. Proper delegate methods will be called during the process.
     
     - parameter central manager that will be used to connect to the peripheral
     - parameter target: the DFU target peripheral
     
     - returns: the initiator instance
     
     - seeAlso: peripheralSelector property - a selector used when scanning for a device in DFU Bootloader mode
     in case you want to update a Softdevice and Application from a single ZIP Distribution Packet.
     */
    public init(centralManager:CBCentralManager, target:CBPeripheral) {
        self.centralManager = centralManager
        // Just to be sure that manager is not scanning
        self.centralManager.stopScan()
        self.target = target
        self.peripheralSelector = DFUPeripheralSelector(secureDFU: true)
    }
    
    /**
     Sets the file with the firmware. The file must be specified before calling `start()` method,
     and must not be nil.
     
     - parameter file: The firmware wrapper object
     
     - returns: the initiator instance to allow chain use
     */
    open func withFirmwareFile(_ file:DFUFirmware) -> SecureDFUServiceInitiator {
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
     
     - returns: n object that can be used to controll the DFU operation.
     */
    open func start() -> SecureDFUServiceController? {
        // The firmware file must be specified before calling `start()`
        if file == nil{
            delegate?.didErrorOccur(DFUError.fileNotSpecified, withMessage: "Firmare not specified")
            return nil
        }

        let executor = SecureDFUExecutor(self)
        let controller = SecureDFUServiceController(executor)
        executor.start()
        self.logger?.logWith(.verbose, message: "Started Secure DFU service controller")
        return controller
    }
}
