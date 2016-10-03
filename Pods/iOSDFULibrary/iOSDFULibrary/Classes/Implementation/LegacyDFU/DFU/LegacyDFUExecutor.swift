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

internal class LegacyDFUExecutor : DFUPeripheralDelegate {
    
    /// Retry counter for peripheral invalid state issue
    fileprivate var invalidStateRetryCount = 3

    /// The DFU Service Initiator instance that was used to start the service.
    fileprivate let initiator:LegacyDFUServiceInitiator

    /// The service delegate will be informed about status changes and errors.
    fileprivate var delegate:DFUServiceDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.delegate
    }
    
    /// The progress delegate will be informed about current upload progress.
    fileprivate var progressDelegate:DFUProgressDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.progressDelegate
    }
    
    /// The DFU Target peripheral. The peripheral keeps the cyclic reference to the DFUExecutor preventing both from being disposed before DFU ends.
    fileprivate var peripheral:LegacyDFUPeripheral
    /// The firmware to be sent over-the-air
    fileprivate var firmware:DFUFirmware
    
    fileprivate var error:(error:DFUError, message:String)?
    
    // MARK: - Initialization
    
    init(_ initiator:LegacyDFUServiceInitiator) {
        self.initiator = initiator
        self.firmware = initiator.file!
        self.peripheral = LegacyDFUPeripheral(initiator)
    }
    
    // MARK: - DFU Controller methods
    
    func start() {
        self.error = nil
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.connecting)
        })
        peripheral.delegate = self
        peripheral.connect()
    }
    
    func pause() -> Bool {
        return peripheral.pause()
    }
    
    func resume() -> Bool {
        return peripheral.resume()
    }
    
    func abort() -> Bool {
        return peripheral.abort()
    }
    
    // MARK: - DFU Peripheral Delegate methods
    
    func onDeviceReady() {
        if firmware.initPacket == nil && peripheral.isInitPacketRequired() {
            didErrorOccur(DFUError.extendedInitPacketRequired, withMessage: "The init packet is required by the target device")
            return
        }
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.starting)
        })
        peripheral.enableControlPoint()
    }
    
    func onControlPointEnabled() {
        // Check whether the target is in application or bootloader mode
        if peripheral.isInApplicationMode(initiator.forceDfu) {
            DispatchQueue.main.async(execute: {
                self.delegate?.didStateChangedTo(DFUState.enablingDfuMode)
            })
            peripheral.jumpToBootloader()
        } else {
            // The device is ready to proceed with DFU
            peripheral.sendStartDfuWithFirmwareType(firmware.currentPartType, andSize: firmware.currentPartSize)
        }
    }
    
    func onStartDfuWithTypeNotSupported() {
        // The DFU target has an old implementation of DFU Bootloader, that allows only the application 
        // to be updated.
        
        if firmware.currentPartType == FIRMWARE_TYPE_APPLICATION {
            // Try using the old DFU Start command, without type
            peripheral.sendStartDfuWithFirmwareSize(firmware.currentPartSize)
        } else {
            // Operation can not be continued
            didErrorOccur(DFUError.remoteNotSupported, withMessage: "Updating Softdevice or Bootloader is not supported")
        }
    }
    
    func onDeviceReportedInvalidState() {
        if invalidStateRetryCount > 0 {
            self.initiator.logger?.logWith(.warning, message: "Last upload interrupted. Restarting device, attempts left : \(invalidStateRetryCount)")
                invalidStateRetryCount -= 1
                self.peripheral.connect()
        }else{
            self.didErrorOccur(.remoteInvalidState, withMessage: "Peripheral is in an invalid state, please try to reset and start over again.")
        }
    }

    func onStartDfuSent() {
        // Check if the init packet is present for this part
        if let initPacket = firmware.initPacket {
            peripheral.sendInitPacket(initPacket)
            return
        }
        
        sendFirmware()
    }
    
    func onInitPacketSent() {
        sendFirmware()
    }
    
    /**
     Sends the current part of the firmware to the target DFU device.
     */
    func sendFirmware() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.uploading)
        })
        // First the service will send the number of packets of firmware data to be received 
        // by the DFU target before sending a new Packet Receipt Notification.
        // After receiving status Success it will send the firmware.
        peripheral.sendFirmware(firmware, withPacketReceiptNotificationNumber: initiator.packetReceiptNotificationParameter, andReportProgressTo: progressDelegate)
    }
    
    func onFirmwareSent() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.validating)
        })
        peripheral.validateFirmware()
    }
    
    func onFirmwareVerified() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.disconnecting)
        })
        peripheral.activateAndReset()
    }
    
    func onTransferComplete() {
        // Check if there is another part of the firmware that has to be sent
        if firmware.hasNextPart() {
            firmware.switchToNextPart()
            
            peripheral.switchToNewPeripheralAndConnect(initiator.peripheralSelector)
            return
        }
        // If not, we are done here. Congratulations!
        didDeviceDisconnect()
    }
    
    func onAborted() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.aborted)
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didDeviceFailToConnect() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didErrorOccur(DFUError.failedToConnect, withMessage: "Device failed to connect")
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didDeviceDisconnect() {
        // The device is now disconnected. Check if there was an error that needs to be reported now
        DispatchQueue.main.async(execute: {
            if let error = self.error {
                self.delegate?.didErrorOccur(error.error, withMessage: error.message)
            } else {
                // If no, the DFU operation is complete
                self.delegate?.didStateChangedTo(DFUState.completed)
            }
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didDeviceDisconnectWithError(_ error: Error) {
        DispatchQueue.main.async(execute: {
            self.delegate?.didErrorOccur(DFUError.deviceDisconnected, withMessage: "\(error.localizedDescription) (code: \((error as NSError).code))")
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didErrorOccur(_ error:DFUError, withMessage message:String) {
        // Save the error. It will be reported when the device disconnects
        self.error = (error, message)
        peripheral.disconnect()
    }
}
