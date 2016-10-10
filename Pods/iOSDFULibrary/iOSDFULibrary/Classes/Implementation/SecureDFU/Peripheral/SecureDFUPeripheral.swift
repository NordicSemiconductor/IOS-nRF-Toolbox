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

internal class SecureDFUPeripheral: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    /// Bluetooth Central Manager used to scan for the peripheral.
    fileprivate let centralManager:CBCentralManager
    /// The DFU Target peripheral.
    fileprivate var peripheral:CBPeripheral?
    
    /// The optional logger delegate.
    fileprivate var logger:LoggerHelper
    /// The peripheral delegate.
    internal var delegate:SecureDFUPeripheralDelegate?
    /// Selector used to find the advertising peripheral in DFU Bootloader mode.
    fileprivate var peripheralSelector:DFUPeripheralSelector?
    
    // MARK: - DFU properties
    
    /// The DFU Service instance. Not nil when found on the peripheral.
    fileprivate var dfuService:SecureDFUService?
    /// A flag set when upload has been paused.
    fileprivate var paused = false
    /// A flag set when upload has been aborted.
    fileprivate var aborted = false
    /// Maxmimum length reported by peripheral
    fileprivate var maxWtireLength : UInt32 = 0
    /// Resetting flag, when the peripheral disconnects to reconncet
    internal var isResetting = false
    
    // MARK: - Initialization
    
    init(_ initiator:SecureDFUServiceInitiator) {
        self.centralManager = initiator.centralManager
        self.peripheral = initiator.target
        self.logger = LoggerHelper(initiator.logger)
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
        centralManager.connect(peripheral!, options: nil)
    }
    
    /**
     Disconnects the target device.
     */
    func disconnect() {
        if peripheral != nil {
            logger.v("Disconnecting...")
            logger.d("centralManager.cancelPeripheralConnection(peripheral)")
            centralManager.cancelPeripheralConnection(peripheral!)
        }
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
            disconnect()
        }
    }
    
    /**
     Returns whether the Init Packet is required by the target DFU device.
     
     - returns: true if init packet is required, false if not. Init packet is required
     since DFU Bootloader version 0.5 (SDK 7.0.0).
     */
    func isInitPacketRequired() -> Bool {
        return false
    }
    
    /**
     Enables notifications on DFU Control Point characteristic.
     */
    func enableControlPoint() {
        dfuService?.enableControlPoint(onSuccess: {_ in 
            self.delegate?.onControlPointEnabled()
            }, onError: { (error, message) in
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }

    /**
     Reads object info command to get max write size
    */
    func ReadObjectInfoCommand() {
        dfuService?.readObjectInfoCommand(onSuccess: { (responseData) in
            //Parse response data
            let count = (responseData?.count)! / MemoryLayout<UInt32>.size
            var array = [UInt32](repeating: 0, count: count)
            let range = count * MemoryLayout<UInt32>.size
            (responseData as NSData?)?.getBytes(&array, length: range)
            self.logger.i("Read Object Info Command : received data : MaxLen:\(array[0]), Offset:\(array[1]), CRC: \(array[2]))")
            self.delegate?.objectInfoReadCommandCompleted(array[0], offset: array[1], crc: array[2])
            }, onError: { (error, message) in
                self.logger.e("Error occured: \(error), \(message)")
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }

    /**
     Reads object info data to get max write size
     */
    func ReadObjectInfoData() {
        dfuService?.readObjectInfoData(onSuccess: { (responseData) in
            //Parse resonpes data
            let count = (responseData?.count)! / MemoryLayout<UInt32>.size
            var array = [UInt32](repeating: 0, count: count)
            let range = count * MemoryLayout<UInt32>.size
            (responseData as NSData?)?.getBytes(&array, length: range)
            self.logger.i("Read Object Info Data : received data : MaxLen:\(array[0]), Offset:\(array[1]), CRC: \(array[2]))")
            self.delegate?.objectInfoReadDataCompleted(array[0], offset: array[1], crc: array[2])
            }, onError: { (error, message) in
                self.logger.e("Error occured: \(error), \(message)")
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }

    /**
     Reads Extended error
    */
    func readExtendedError() {
        self.dfuService?.readError(onSuccess: { (responseData) in
            self.logger.e("Read extended error data: \(responseData!)")
            }, onError: { (error, message) in
                self.logger.e("Failed to read extended error: \(message)")
        })
    }
    
    /**
     ExtendedError completion
    */
    func readExtendedErrorCompleted(_ message : String) {
        //TODO: implement
    }

    /**
     Send firmware data
    */
    func sendFirmwareChunk(_ firmware: DFUFirmware, andChunkRange aRange : Range<Int>, andPacketCount aCount : UInt16, andProgressDelegate aProgressDelegate : DFUProgressDelegate) {

        self.dfuService?.sendFirmwareChunk(aRange, inFirmware: firmware, andPacketReceiptCount: aCount, andProgressDelegate: aProgressDelegate, andCompletionHandler: { (responseData) in
            self.delegate?.firmwareChunkSendcomplete()
            }, andErrorHandler: { (error, message) in
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })

    }

    /**
    Creates object data
    */
    func createObjectData(withLength length: UInt32) {
        dfuService?.createObjectData(withLength: length, onSuccess: { (responseData) in
            self.delegate?.objectCreateDataCompleted(responseData)
            }, onError: { (error, message) in
                self.logger.e("Error occured: \(error), \(message)")
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }

    /**
    Creates an object command
    */
    func createObjectCommand(_ length: UInt32) {
        dfuService?.createObjectCommand(withLength: length, onSuccess: { (responseData) in
            self.delegate?.objectCreateCommandCompleted(responseData)
            }, onError: { (error, message) in
                self.logger.e("Error occured: \(error), \(message)")
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }
    /**
     Set PRN Value
    */
    func setPRNValue(_ aValue : UInt16 = 0) {
        dfuService?.setPacketReceiptNotificationValue(aValue, onSuccess: { (responseData) in
            self.delegate?.setPRNValueCompleted()
            }, onError: { (error, message) in
                self.logger.e("Error occured: \(error), \(message)")
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }
    
    /**
     Send Init packet
    */
    func sendInitpacket(_ packetData : Data){
        dfuService?.sendInitPacket(withdata: packetData)
        self.delegate?.initPacketSendCompleted()
    }
    
    /**
     Send calculate Checksum comand
    */
    func sendCalculateChecksumCommand() {
        dfuService?.calculateChecksumCommand(onSuccess: { (responseData) in
            //Parse resonpse data
            let count = (responseData?.count)! / MemoryLayout<UInt32>.size
            var array = [UInt32](repeating: 0, count: count)
            let range = count * MemoryLayout<UInt32>.size
            (responseData as NSData?)?.getBytes(&array, length: range)
            self.delegate?.calculateChecksumCompleted(array[0], CRC: array[1])
            }, onError: { (error, message) in
                self.logger.e("Error occured: \(error), \(message)")
                self.delegate?.onErrorOccured(withError: error, andMessage: message)
        })
    }
    
    /**
     Send execute command
    */
    func sendExecuteCommand() {
        dfuService?.executeCommand(onSuccess: { (responseData) in
                self.delegate?.executeCommandCompleted()
            }, onError: { (error, message) in
                if error == SecureDFUError.extendedError {
                    self.logger.e("Extended error occured, attempting to read.")
                    self.readExtendedError()
                }else{
                    self.logger.e("Error occured: \(error), \(message)")
                    self.delegate?.onErrorOccured(withError: error, andMessage: message)
                }
        })
    }

    /**
     Checks whether the target device is in application mode and must be switched to the DFU mode.
     
     - parameter forceDfu: should the service assume the device is in DFU Bootloader mode when 
     DFU Version characteristic does not exist and at least one other service has been found on the device.
     
     - returns: true if device needs buttonless jump to DFU Bootloader mode
     */
    func isInApplicationMode(_ forceDfu:Bool) -> Bool {
        let applicationMode = dfuService!.isInApplicationMode() ?? !forceDfu
        
        if applicationMode {
            logger.w("Application with buttonless update found")
        }
        
        return applicationMode
    }
    
    /**
     Scans for a next device to connect to. When device is found and selected, it connects to it.
     
     After updating the Softdevice the device may start advertising with an address incremented by 1.
     A BLE scan needs to be done to find this new peripheral (it's the same device, but as it
     advertises with a new address, from iOS point of view it completly different device).
     
     - parameter selector: a selector used to select a device in DFU Bootloader mode
     */
    func switchToNewPeripheralAndConnect(_ selector:DFUPeripheralSelector) {
        // Release the previous peripheral
        self.peripheral!.delegate = nil
        self.peripheral = nil
        self.peripheralSelector = selector
        logger.v("Scanning for the DFU Bootloader...")
        centralManager.scanForPeripherals(withServices: selector.filterBy(), options: nil)
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

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logCentralManagerState(CBCentralManagerState(rawValue: central.state.rawValue)!)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        cleanUp()
        
        logger.d("[Callback] Central Manager did connect peripheral")
        let name = peripheral.name ?? "Unknown device"
        logger.i("Connected to \(name)")
        
        // Discover all device services. In case there is no DFU Version characteristic the service
        // will determine whether to jump to the DFU Bootloader mode, or not, based on number of services.
        logger.v("Discovering services...")
        logger.d("periphera.discoverServices(nil)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
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
        delegate?.didDeviceFailToConnect()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if isResetting == true {
            if error != nil {
                logger.i("Resetting peripheral")
                logger.d("[Callback] Central Manager did disconnect peripheral with error while resetting")
            } else {
                logger.i("Resetting peripheral")
                logger.d("[Callback] Central Manager did disconnect peripheral without error")
            }
            return
        }
        if aborted == true {
            delegate?.onAborted()
            aborted = false
            return
        }
        if error != nil {
            if let anError = error as? CBError {
                if anError.code == CBError.Code.peripheralDisconnected ||
                    anError.code == CBError.Code.connectionTimeout {
                    logger.i("Disconnected by the remote device")
                }else{
                    logger.d("[Callback] Central Manager did disconnect peripheral without error")
                    delegate?.peripheralDisconnected()
                    return
                }
            }
            //Unable to cast error
            logger.d("[Callback] Central Manager did disconnect peripheral")
            logger.i("Disconnected")
            logger.e(error!)
            delegate?.peripheralDisconnected(withError: error! as NSError)
        } else {
            logger.d("[Callback] Central Manager did disconnect peripheral without error")
            logger.i("Disconnected")
            delegate?.peripheralDisconnected()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralSelector = peripheralSelector {
            // Is this a device we are looking for?
            if peripheralSelector.select(peripheral, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI) {
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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            logger.e("Services discovery failed")
            logger.e(error!)
            delegate?.onErrorOccured(withError: SecureDFUError.serviceDiscoveryFailed, andMessage: "Service discovery failed")
        } else {
            logger.i("Services discovered")
            
            // Find the DFU Service
            let services = peripheral.services!
            for service in services {
                if SecureDFUService.matches(service) {
                    logger.v("Secure DFU Service found")
                    
                    // DFU Service has been found. Discover characteristics...
                    dfuService = SecureDFUService(service, logger)
                    dfuService!.discoverCharacteristics(
                        onSuccess: { (data) -> () in self.delegate?.onDeviceReady() },
                        onError: { (error, message) -> () in self.delegate?.onErrorOccured(withError: error, andMessage: message) }
                    )
                }
            }
            
            if dfuService == nil {
                logger.e("Secure DFU Service not found")
                // The device does not support DFU, nor buttonless jump
                delegate?.onErrorOccured(withError:SecureDFUError.deviceNotSupported, andMessage: "Secure DFU Service not found")
            }
        }
    }
    
    // MARK: - Private methods
    
    fileprivate func cleanUp() {
        dfuService = nil
    }
    
    fileprivate func logCentralManagerState(_ state:CBCentralManagerState) {
        var stateAsString:String
        
        switch (state) {
        case .poweredOn:
            stateAsString = "Powered ON"
            break
            
        case .poweredOff:
            stateAsString = "Powered OFF"
            break
            
        case .resetting:
            stateAsString = "Resetting"
            break
            
        case .unauthorized:
            stateAsString = "Unauthorized"
            break
            
        case .unsupported:
            stateAsString = "Unsupported"
            break
            
        case .unknown:
            stateAsString = "Unknown"
            break
        }
        logger.d("[Callback] Central Manager did update state to: \(stateAsString)")
    }
}
