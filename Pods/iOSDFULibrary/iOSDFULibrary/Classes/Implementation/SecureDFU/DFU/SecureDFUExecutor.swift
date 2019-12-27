/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

internal class SecureDFUExecutor : DFUExecutor, SecureDFUPeripheralDelegate {
    typealias DFUPeripheralType = SecureDFUPeripheral
    
    internal let initiator  : DFUServiceInitiator
    internal let logger     : LoggerHelper
    internal let peripheral : SecureDFUPeripheral
    internal var firmware   : DFUFirmware
    internal var error      : (error: DFUError, message: String)?
    
    private var firmwareRanges  : [Range<Int>]?
    private var currentRangeIdx : Int = 0
    
    private var maxLen          : UInt32?
    private var offset          : UInt32?
    private var crc             : UInt32?
    
    private var initPacketSent  : Bool = false
    private var firmwareSent    : Bool = false
    private var uploadStartTime : CFAbsoluteTime?
    
    /// Retry counter in case the peripheral returns invalid CRC.
    private let MaxRetryCount = 3
    private var retryCount: Int
    
    // MARK: - Initialization
    required init(_ initiator: DFUServiceInitiator, _ logger: LoggerHelper) {
        self.initiator  = initiator
        self.logger     = logger
        self.firmware   = initiator.file!
        self.peripheral = SecureDFUPeripheral(initiator, logger)
        
        self.retryCount = MaxRetryCount
    }
    
    func start() {
        error = nil
        peripheral.delegate = self
        peripheral.start() // -> peripheralDidBecomeReady() will be called when the device is
                           //    connected and DFU services was found.
    }
    
    // MARK: - DFU Peripheral Delegate methods
    
    func peripheralDidBecomeReady() {
        if firmware.initPacket == nil && peripheral.isInitPacketRequired() {
            error(.extendedInitPacketRequired, didOccurWithMessage: "The init packet is required by the target device")
            return
        }
        resetFirmwareRanges()
        
        delegate {
            $0.dfuStateDidChange(to: .starting)
        }
        peripheral.enableControlPoint() // -> peripheralDidEnableControlPoint() will be called when done.
    }
    
    func peripheralDidEnableControlPoint() {
        // Check whether the target is in application or bootloader mode.
        if peripheral.isInApplicationMode(initiator.forceDfu) {
            delegate {
                $0.dfuStateDidChange(to: .enablingDfuMode)
            }
            peripheral.jumpToBootloader() // -> peripheralDidBecomeReady() will be called again,
                                          //    when connected to the Bootloader.
        } else {
            // The device is ready to proceed with DFU.
            
            // Start by reading command object info to get the maximum write size.
            peripheral.readCommandObjectInfo() // -> peripheralDidSendCommandObjectInfo(...) will be
                                               //    called when object received.
        }
    }
    
    func peripheralDidSendCommandObjectInfo(maxLen: UInt32, offset: UInt32, crc: UInt32 ) {
        self.maxLen = maxLen
        self.offset = offset
        self.crc = crc
        
        // Was Init packet sent, at least partially, before?
        if offset > 0 {
            // If we are allowed to resume, then verify CRC of the part that was sent before.
            if !initiator.disableResume && verifyCRC(for: firmware.initPacket!,
                                                     andPacketOffset: offset, matches: crc) {
                // Resume sending Init Packet
                if offset < UInt32(firmware.initPacket!.count) {
                    logger.a("Resuming sending Init packet...")
                    
                    // We need to send rest of the Init packet, but before that let's make sure
                    // the PRNs are disabled.
                    peripheral.setPRNValue(0) // -> peripheralDidSetPRNValue() will be called.
                } else {
                    // The same Init Packet was already sent. We must execute it, as it may have
                    // not been executed before.
                    logger.a("Received CRC match Init packet")
                    peripheral.sendExecuteCommand(forCommandObject: true) // -> peripheralDidExecuteObject() or
                                                                          //    peripheralRejectedCommandObject(...)
                                                                          //    will be called.
                }
            } else {
                // Start new update. We are either flashing a different firmware,
                // or we are resuming from a BL/SD + App and need to start all over again.
                self.offset = 0
                self.crc = 0
                peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count)) // -> peripheralDidCreateCommandObject()
            }
        } else {
            // No Init Packet was sent before. Create the Command object.
            peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count)) // -> peripheralDidCreateCommandObject()
        }
    }
    
    func peripheralDidCreateCommandObject() {
        // Disable PRNs for first time while we write Init file.
        peripheral.setPRNValue(0) // -> peripheralDidSetPRNValue() will be called/
    }
    
    func peripheralDidSetPRNValue() {
        if initPacketSent == false {
            // PRNs are disabled, we may sent Init Packet data.
            sendInitPacket(fromOffset: offset!) // -> peripheralDidReceiveInitPacket() will be called.
        } else {
            // PRNs are ready, check out the Data object.
            peripheral.readDataObjectInfo() // -> peripheralDidSendDataObjectInfo(...) will be called.
        }
    }
    
    func peripheralDidReceiveInitPacket() {
        logger.a(String(format: "Command object sent (CRC = %08X)", crc32(data: firmware.initPacket!)))
        
        // Init Packet sent. Let's check the CRC before executing it.
        peripheral.sendCalculateChecksumCommand() // -> peripheralDidSendChecksum(...) will be called.
    }
    
    func peripheralDidSendChecksum(offset: UInt32, crc: UInt32) {
        self.crc    = crc
        self.offset = offset
        
        if initPacketSent == false {
            // Verify CRC
            if verifyCRC(for: firmware.initPacket!, andPacketOffset: UInt32(firmware.initPacket!.count), matches: crc) {
                // Init Packet sent correctly.
                crcOk()
                
                // It must be now executed.
                peripheral.sendExecuteCommand(forCommandObject: true) // -> peripheralDidExecuteObject() or
                                                                      //    peripheralRejectedCommandObject(...)
                                                                      //    will be called.
            } else {
                // The CRC does not match, let's start from the beginning.
                retryOrReportCrcError({
                    self.offset = 0
                    self.crc = 0
                    peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count)) // -> peripheralDidCreateCommandObject()
                })
            }
        } else {
            // Verify CRC
            if verifyCRC(for: firmware.data, andPacketOffset: offset, matches: crc) {
                // Data object sent correctly.
                crcOk()
                
                // It must be now executed.
                firmwareSent = offset == UInt32(firmware.data.count)
                peripheral.sendExecuteCommand(andActivateIf: firmwareSent) // -> peripheralDidExecuteObject()
            } else {
                retryOrReportCrcError({
                    createDataObject(currentRangeIdx) // -> peripheralDidCreateDataObject() will be called.
                })
            }
        }
    }
    
    func peripheralRejectedCommandObject(withError remoteError: DFUError, andMessage message: String) {
        // If the terget device has rejected the firtst part, try sending the second part.
        // If may be that the SD+BL were flashed before and can't be updated again due to
        // sd-req and bootloader-version parameters set in the init packet.
        // In that case app update should be possible.
        if firmware.hasNextPart() {
            firmware.switchToNextPart()
            
            logger.w("Invalid system components. Trying to send application")
            
            // New Init Packet has to be sent. Create the Command object.
            offset = 0
            crc = 0
            peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count)) // -> peripheralDidCreateCommandObject()
        } else {
            error(remoteError, didOccurWithMessage: message)
        }
    }
    
    func peripheralDidExecuteObject() {
        if initPacketSent == false {
            logger.a("Command object executed")
            initPacketSent = true
            // Set the correct PRN value. If initiator.packetReceiptNotificationParameter is 0
            // and PRNs were already disabled to send the Init packet, this method will immediately
            // call peripheralDidSetPRNValue() callback.
            peripheral.setPRNValue(initiator.packetReceiptNotificationParameter) // -> peripheralDidSetPRNValue() will be called.
        } else {
            logger.a("Data object executed")
            
            if firmwareSent == false {
                currentRangeIdx += 1
                createDataObject(currentRangeIdx) // -> peripheralDidCreateDataObject() will be called.
            } else {
                // The last data object was sent.
                // Now the device will reset itself and onTransferCompleted() method will ba called
                // (from the extension).
                let interval = CFAbsoluteTimeGetCurrent() - uploadStartTime! as CFTimeInterval
                logger.a("Upload completed in \(interval.format(".2")) seconds")
                
                delegate {
                    $0.dfuStateDidChange(to: .disconnecting)
                }
            }
        }
    }
    
    func peripheralDidSendDataObjectInfo(maxLen: UInt32, offset: UInt32, crc: UInt32 ) {
        self.maxLen = maxLen
        self.offset = offset
        self.crc    = crc
        
        // This is the initial state, if ranges aren't set, assume this is the first
        // or the only stage in the DFU process. The Init packet was already sent and executed.
        if firmwareRanges == nil {
            // Split firmware into smaller object of at most maxLen bytes, if firmware is bigger
            // than maxLen.
            firmwareRanges = calculateFirmwareRanges(Int(maxLen))
            currentRangeIdx = 0
        }
        
        delegate {
            $0.dfuStateDidChange(to: .uploading)
        }
        
        if offset > 0 {
            // Find the current range index.
            currentRangeIdx = 0
            for range in firmwareRanges! {
                if range.contains(Int(offset)) {
                    break
                }
                currentRangeIdx += 1
            }
            
            if verifyCRC(for: firmware.data, andPacketOffset: offset, matches: crc) {
                logger.i("\(offset) bytes of data sent before, CRC match")
                // Did we sent the whole firmware?
                if offset == UInt32(firmware.data.count) {
                    firmwareSent = true
                    peripheral.sendExecuteCommand(andActivateIf: firmwareSent) // -> peripheralDidExecuteObject() will be called.
                } else {
                    logger.i("Resuming uploading firmware...")
                    
                    // If the whole object was sent before, make sure it's executed.
                    if (offset % maxLen) == 0 {
                        // currentRangeIdx won't go below 0 because offset > 0 and offset % maxLen == 0
                        currentRangeIdx -= 1
                        peripheral.sendExecuteCommand() // -> peripheralDidExecuteObject() will be called.
                    } else {
                        // Otherwise, continue sending the current object from given offset.
                        sendDataObject(currentRangeIdx, from: offset) // -> peripheralDidReceiveObject() will be called.
                    }
                }
            } else {
                // If offset % maxLen and CRC does not match it means that the whole object needs
                // to be sent again.
                if (offset % maxLen) == 0 {
                    // currentRangeIdx won't go below 0 because offset > 0 and offset % maxLen == 0
                    currentRangeIdx -= 1
                }
                retryOrReportCrcError({
                    createDataObject(currentRangeIdx) // -> peripheralDidCreateDataObject() will be called.
                })
            }
        } else {
            // Create the first data object
            createDataObject(currentRangeIdx) // -> peripheralDidCreateDataObject() will be called.
        }
    }
    
    func peripheralDidCreateDataObject() {
        logger.i("Data object \(currentRangeIdx + 1)/\(firmwareRanges!.count) created")
        // For SDK 15.x and 16 the bootloader needs some time before it's ready to receive data.
        // Otherwise, some packets may be discarded and the received checksum will not match.
        if currentRangeIdx == 0 {
            logger.d("wait(400)")
            initiator.queue.asyncAfter(deadline: .now() + .milliseconds(400)) {
                self.sendDataObject(self.currentRangeIdx) // -> peripheralDidReceiveObject() will be called.
            }
        } else {
            sendDataObject(currentRangeIdx) // -> peripheralDidReceiveObject() will be called.
        }
    }
    
    func peripheralDidReceiveObject() {
        peripheral.sendCalculateChecksumCommand() // -> peripheralDidSendChecksum(...) will be called.
    }
    
    // MARK: - Private methods
    
    private func retryOrReportCrcError(_ operation:()->()) {
        retryCount -= 1
        if retryCount > 0 {
            logger.w("CRC does not match! Retrying...")
            operation()
        } else {
            logger.e("CRC does not match!")
            error(.crcError, didOccurWithMessage: "Sending firmware failed")
        }
    }
    
    private func crcOk() {
        retryCount = MaxRetryCount
    }
    
    /**
     Resets firmware ranges and progress flags.
     
     This method should be called before sending each part of the firmware.
     */
    private func resetFirmwareRanges() {
        currentRangeIdx = 0
        firmwareRanges  = nil
        initPacketSent  = false
        firmwareSent    = false
        uploadStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    /**
     Calculates the firmware ranges.
     
     In Secure DFU the firmware is sent as separate 'objects', where each object is at most
     'maxLen' long. This method creates a list of ranges that will be used to send data to the
     peripheral, for example: 0 ..< 4096, 4096 ..< 5000 in case the firmware was 5000 bytes long.
     
     - parameter maxLen: The maximum length of an object.
     
     - returns: The array of ranges.
     */
    private func calculateFirmwareRanges(_ maxLen: Int) -> [Range<Int>] {
        var totalLength = firmware.data.count
        var ranges: [Range<Int>] = []
        ranges.reserveCapacity((totalLength + maxLen - 1) / maxLen)
        
        var partIdx = 0
        while totalLength > 0 {
            if totalLength > maxLen {
                ranges.append(partIdx * maxLen..<partIdx * maxLen + maxLen)
                totalLength -= maxLen
            } else {
                ranges.append(partIdx * maxLen..<partIdx * maxLen + totalLength)
                totalLength = 0
            }
            partIdx += 1
        }
        
        return ranges
    }
    
    /**
     Verifies if the CRC-32 of the data from byte 0 to given offset matches the given CRC value.
     
     - parameter data:   Firmware or Init packet data.
     - parameter offset: Number of bytes that should be used for CRC calculation.
     - parameter crc:    The CRC obtained from the DFU Target to be matched.
     
     - returns: `True` if CRCs are identical, `false` otherwise.
     */
    private func verifyCRC(for data: Data, andPacketOffset offset: UInt32, matches crc: UInt32) -> Bool {
        // Edge case where a different objcet might be flashed with a biger init file.
        if offset > UInt32(data.count) {
            return false
        }
        // Get data form 0 up to the offset the peripheral has reproted.
        let offsetData : Data = (data.subdata(in: 0 ..< Int(offset)))
        let calculatedCRC = crc32(data: offsetData)
        
        // This returns true if the current data packet's CRC matches the current firmware's
        // packet CRC.
        return calculatedCRC == crc
    }
    
    /**
     Sends the Init packet starting from the given offset. This method is asynchronous, it calls
     peripheralDidReceiveInitPacket() callback when done.
     
     - parameter offset: The starting offset from which the Init Packet should be sent.
                         This allows resuming uploading the Init Packet.
     */
    private func sendInitPacket(fromOffset offset: UInt32) {
        let initPacketLength = UInt32(firmware.initPacket!.count)
        let data = firmware.initPacket!.subdata(in: Int(offset) ..< Int(initPacketLength - offset))
        
        // Send following bytes of init packet (offset may be 0).
        peripheral.sendInitPacket(data) // -> peripheralDidReceiveInitPacket() will be called.
    }
    
    /**
     Creates the new data object with length equal to the length of the range with given index.
     The ranges were calculated using `calculateFirmwareRanges()`.
     
     - parameter rangeIdx: Index of a range of the firmware.
     */
    private func createDataObject(_ rangeIdx: Int) {
        let currentRange = firmwareRanges![rangeIdx]
        peripheral.createDataObject(withLength: UInt32(currentRange.upperBound - currentRange.lowerBound))
        // -> peripheralDidCreateDataObject() will be called.
    }
    
    /**
     This method sends the bytes from the range with given index.
     If the resumeOffset is set and equal to lower bound of the given range it will create
     the object instead. When created, a `onObjectCreated()` method will be called which will
     call this method again, now with the offset parameter equal `nil`.
     
     - parameter rangeIdx:     Index of the range to be sent. The ranges were calculated
                               using `calculateFirmwareRanges()`.
     - parameter resumeOffset: If set, this method will send only the part of firmware from
                               the range. The offset must be inside the given range.
     */
    private func sendDataObject(_ rangeIdx: Int, from resumeOffset: UInt32? = nil) {
        var aRange = firmwareRanges![rangeIdx]
        
        if let resumeOffset = resumeOffset {
            if UInt32(aRange.lowerBound) == resumeOffset {
                // We reached the end of previous object so a new one must be created.
                createDataObject(rangeIdx)
                return
            }
            
            // This is a resuming object, recalculate location and size.
            let newLength = aRange.lowerBound + (aRange.upperBound - aRange.lowerBound) - Int(offset!)
            aRange = Int(resumeOffset) ..< newLength + Int(resumeOffset)
        }
        
        peripheral.sendNextObject(from: aRange, of: firmware,
                                  andReportProgressTo: initiator.progressDelegate,
                                  on: initiator.progressDelegateQueue)
        // -> peripheralDidReceiveObject() will be called.
    }
}
