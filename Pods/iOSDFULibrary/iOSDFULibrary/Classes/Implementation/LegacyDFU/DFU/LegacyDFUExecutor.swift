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

internal class LegacyDFUExecutor : DFUExecutor, LegacyDFUPeripheralDelegate {
    typealias DFUPeripheralType = LegacyDFUPeripheral
    
    internal let initiator  : DFUServiceInitiator
    internal let peripheral : LegacyDFUPeripheral
    internal var firmware   : DFUFirmware
    internal var error      : (error: DFUError, message: String)?
    
    /// Retry counter for peripheral invalid state issue
    private let MaxRetryCount = 1
    private var invalidStateRetryCount: Int
    
    // MARK: - Initialization
    
    required init(_ initiator: DFUServiceInitiator) {
        self.initiator  = initiator
        self.peripheral = LegacyDFUPeripheral(initiator)
        self.firmware   = initiator.file!
        
        self.invalidStateRetryCount = MaxRetryCount
    }
    
    func start() {
        error = nil
        peripheral.delegate = self
        peripheral.start()
    }
    
    // MARK: - DFU Peripheral Delegate methods
    
    func peripheralDidBecomeReady() {
        if firmware.initPacket == nil && peripheral.isInitPacketRequired() {
            error(.extendedInitPacketRequired, didOccurWithMessage: "The init packet is required by the target device")
            return
        }
        DispatchQueue.main.async(execute: {
            self.delegate?.dfuStateDidChange(to: .starting)
        })
        peripheral.enableControlPoint()
    }
    
    func peripheralDidEnableControlPoint() {
        // Check whether the target is in application or bootloader mode
        if peripheral.isInApplicationMode(initiator.forceDfu) {
            DispatchQueue.main.async(execute: {
                self.delegate?.dfuStateDidChange(to: .enablingDfuMode)
            })
            peripheral.jumpToBootloader()
        } else {
            // The device is ready to proceed with DFU
            peripheral.sendStartDfu(withFirmwareType: firmware.currentPartType, andSize: firmware.currentPartSize)
        }
    }
    
    func peripheralDidFailToStartDfuWithType() {
        // The DFU target has an old implementation of DFU Bootloader, that allows only the application
        // to be updated.
        
        if firmware.currentPartType == FIRMWARE_TYPE_APPLICATION {
            // Try using the old DFU Start command, without type
            peripheral.sendStartDfu(withFirmwareSize: firmware.currentPartSize)
        } else {
            // Operation can not be continued
            error(.remoteLegacyDFUNotSupported, didOccurWithMessage: "Updating Softdevice or Bootloader is not supported")
        }
    }

    func peripheralDidStartDfu() {
        // Check if the init packet is present for this part
        if let initPacket = firmware.initPacket {
            peripheral.sendInitPacket(initPacket)
            return
        }
        
        sendFirmware()
    }
    
    func peripheralDidReceiveInitPacket() {
        sendFirmware()
    }
    
    func peripheralDidReceiveFirmware() {
        DispatchQueue.main.async(execute: {
            self.delegate?.dfuStateDidChange(to: .validating)
        })
        peripheral.validateFirmware()
    }
    
    func peripheralDidVerifyFirmware() {
        DispatchQueue.main.async(execute: {
            self.delegate?.dfuStateDidChange(to: .disconnecting)
        })
        peripheral.activateAndReset()
    }
    
    func peripheralDidReportInvalidState() {
        if invalidStateRetryCount > 0 {
            logWith(.warning, message: "Retrying...")
            invalidStateRetryCount -= 1
            peripheral.start()
        } else {
            error(.remoteLegacyDFUInvalidState, didOccurWithMessage: "Peripheral is in an invalid state, please try to reset and start over again.")
        }
    }
    
    // MARK: - Private methods
    
    /**
     Sends the current part of the firmware to the target DFU device.
     */
    private func sendFirmware() {
        DispatchQueue.main.async(execute: {
            self.delegate?.dfuStateDidChange(to: .uploading)
        })
        // First the service will send the number of packets of firmware data to be received
        // by the DFU target before sending a new Packet Receipt Notification.
        // After receiving status Success it will send the firmware.
        peripheral.sendFirmware(firmware, withPacketReceiptNotificationNumber: initiator.packetReceiptNotificationParameter, andReportProgressTo: progressDelegate)
    }
}
