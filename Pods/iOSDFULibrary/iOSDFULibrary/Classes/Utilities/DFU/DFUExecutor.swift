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

internal class DFUExecutor : DFUPeripheralDelegate {
    /// The DFU Service Initiator instance that was used to start the service.
    private let initiator:DFUServiceInitiator
    
    /// The service delegate will be informed about status changes and errors.
    private var delegate:DFUServiceDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.delegate
    }
    
    /// The progress delegate will be informed about current upload progress.
    private var progressDelegate:DFUProgressDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.progressDelegate
    }
    
    /// The DFU Target peripheral. The peripheral keeps the cyclic reference to the DFUExecutor preventing both from being disposed before DFU ends.
    private var peripheral:DFUPeripheral
    /// The firmware to be sent over-the-air
    private var firmware:DFUFirmware
    
    private var error:(error:DFUError, message:String)?
    
    // MARK: - Initialization
    
    init(_ initiator:DFUServiceInitiator) {
        self.initiator = initiator
        self.firmware = initiator.file!
        self.peripheral = DFUPeripheral(initiator)
    }
    
    // MARK: - DFU Controller methods
    
    func start() {
        self.error = nil
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(State.Connecting)
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
    
    func abort() {
        peripheral.abort()
    }
    
    // MARK: - DFU Peripheral Delegate methods
    
    func onDeviceReady() {
        if firmware.initPacket == nil && peripheral.isInitPacketRequired() {
            didErrorOccur(DFUError.ExtendedInitPacketRequired, withMessage: "The init packet is required by the target device")
            return
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(State.Starting)
        })
        peripheral.enableControlPoint()
    }
    
    func onControlPointEnabled() {
        // Check whether the target is in application or bootloader mode
        if peripheral.isInApplicationMode(initiator.forceDfu) {
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.didStateChangedTo(State.EnablingDfuMode)
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
            didErrorOccur(DFUError.RemoteNotSupported, withMessage: "Updating Softdevice or Bootloader is not supported")
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
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(State.Uploading)
        })
        // First the service will send the number of packets of firmware data to be received 
        // by the DFU target before sending a new Packet Receipt Notification.
        // After receiving status Success it will send the firmware.
        peripheral.sendFirmware(firmware, withPacketReceiptNotificationNumber: initiator.packetReceiptNotificationParameter, andReportProgressTo: progressDelegate)
    }
    
    func onFirmwareSent() {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(State.Validating)
        })
        peripheral.validateFirmware()
    }
    
    func onFirmwareVerified() {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(State.Disconnecting)
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
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(State.Aborted)
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didDeviceFailToConnect() {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didErrorOccur(DFUError.FailedToConnect, withMessage: "Device failed to connect")
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didDeviceDisconnect() {
        // The device is now disconnected. Check if there was an error that needs to be reported now
        dispatch_async(dispatch_get_main_queue(), {
            if let error = self.error {
                self.delegate?.didErrorOccur(error.error, withMessage: error.message)
            } else {
                // If no, the DFU operation is complete
                self.delegate?.didStateChangedTo(State.Completed)
            }
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didDeviceDisconnectWithError(error: NSError) {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didErrorOccur(DFUError.DeviceDisconnected, withMessage: "\(error.localizedDescription) (code: \(error.code))")
        })
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func didErrorOccur(error:DFUError, withMessage message:String) {
        // Save the error. It will be reported when the device disconnects
        self.error = (error, message)
        peripheral.disconnect()
    }
}
