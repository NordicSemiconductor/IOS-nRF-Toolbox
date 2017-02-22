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

internal class SecureDFUExecutor : DFUExecutor, SecureDFUPeripheralDelegate {
    typealias DFUPeripheralType = SecureDFUPeripheral
    
    internal let initiator  : DFUServiceInitiator
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
    
    /// Retry counter in case the peripheral returns invalid CRC
    private let MaxRetryCount = 3
    private var retryCount: Int
    
    // MARK: - Initialization
    required init(_ initiator: DFUServiceInitiator) {
        self.initiator  = initiator
        self.firmware   = initiator.file!
        self.peripheral = SecureDFUPeripheral(initiator)
        
        self.retryCount = MaxRetryCount
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
        resetFirmwareRanges()
        
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
            
            // Start by reading command object info to get the maximum write size.
            peripheral.readCommandObjectInfo()
        }
    }
    
    func peripheralDidSendCommandObjectInfo(maxLen: UInt32, offset: UInt32, crc: UInt32 ) {
        self.maxLen = maxLen
        self.offset = offset
        self.crc = crc
        
        if offset > 0 {
            let match = verifyCRC(for: firmware.initPacket!, andPacketOffset: offset, matches: crc)
            if match {
                // Resume sending Init Packet
                if offset < UInt32(firmware.initPacket!.count) {
                    logWith(.application, message: "Resuming sending Init packet...")
                    
                    // We need to send rest of the Init packet, but before that let's make sure the PRNs are disabled
                    peripheral.setPRNValue(0)
                } else {
                    logWith(.application, message: "Received CRC match Init packet")
                    peripheral.sendExecuteCommand()
                }
            } else {
                // Start new flash, we either are flashing a different firmware
                // or we are resuming from a BL/SD + App and need to start all over again.
                self.offset = 0
                self.crc = 0
                peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count))
            }
        } else {
            peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count))
        }
    }
    
    func peripheralDidCreateCommandObject() {
        // Disable PRNs for first time while we write Init file
        peripheral.setPRNValue(0)
    }
    
    func peripheralDidSetPRNValue() {
        if initPacketSent == false {
            sendInitPacket(fromOffset: offset!)
        } else {
            sendDataObject(currentRangeIdx, from: offset!)
        }
    }
    
    func peripheralDidReceiveInitPacket() {
        logWith(.application, message: String(format: "Command object sent (CRC = %08X)", CRC32(data: firmware.initPacket!).crc))
        peripheral.sendCalculateChecksumCommand()
    }
    
    func peripheralDidSendChecksum(offset: UInt32, crc: UInt32) {
        self.crc    = crc
        self.offset = offset
        
        if initPacketSent == false {
            if verifyCRC(for: firmware.initPacket!, andPacketOffset: UInt32(firmware.initPacket!.count), matches: crc) {
                crcOk()
                peripheral.sendExecuteCommand()
            } else {
                // The CRC does not match, let's start from the beginning
                retryOrReportCrcError({
                    peripheral.createCommandObject(withLength: UInt32(firmware.initPacket!.count))
                })
            }
        } else {
            // Verify CRC
            if verifyCRC(for: firmware.data, andPacketOffset: offset, matches: crc) {
                crcOk()
                firmwareSent = offset == UInt32(firmware.data.count)
                peripheral.sendExecuteCommand(andActivateIf: firmwareSent)
            } else {
                retryOrReportCrcError({
                    createDataObject(currentRangeIdx)
                })
            }
        }
    }
    
    func peripheralDidExecuteObject() {
        if initPacketSent == false {
            logWith(.application, message: "Command object executed")
            initPacketSent = true
            peripheral.readDataObjectInfo()
        } else {
            logWith(.application, message: "Data object executed")
            
            if firmwareSent == false {
                currentRangeIdx += 1
                createDataObject(currentRangeIdx)
            } else {
                // The last data object was sent
                // Now the device will reset itself and onTransferCompleted() method will ba called (from the extension)
                let interval = CFAbsoluteTimeGetCurrent() - uploadStartTime! as CFTimeInterval
                logWith(.application, message: "Upload completed in \(interval.format(".2")) seconds")
                
                DispatchQueue.main.async(execute: {
                    self.delegate?.dfuStateDidChange(to: .disconnecting)
                })
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
            // Split firmware into smaller object of at most maxLen bytes, if firmware is bigger than maxLen
            firmwareRanges = calculateFirmwareRanges(Int(maxLen))
            currentRangeIdx = 0
        }
        
        DispatchQueue.main.async(execute: {
            self.delegate?.dfuStateDidChange(to: .uploading)
        })
        
        if offset > 0 {
            // Find the current range index
            currentRangeIdx = 0
            for range in firmwareRanges! {
                if range.contains(Int(offset)) {
                    break
                }
                currentRangeIdx += 1
            }
            
            let match = verifyCRC(for: firmware.data, andPacketOffset: offset, matches: crc)
            if match {
                logWith(.info, message: "\(offset) bytes of data sent before, CRC match")
                // Did we sent the whole firmware?
                if offset == UInt32(firmware.data.count) {
                    firmwareSent = true
                    peripheral.sendExecuteCommand(andActivateIf: firmwareSent)
                } else {
                    logWith(.info, message: "Resuming uploading firmware...")
                    // If the PRNs are enabled the value must be sent to the target
                    if initiator.packetReceiptNotificationParameter > 0 {
                        peripheral.setPRNValue(initiator.packetReceiptNotificationParameter)
                    } else {
                        // Otherwise we can just start by creating the first object. PRNs were set to 0 before, to send the init packet.
                        // Note: setting PRNs to 0 (disabling them) will not work!
                        
                        // Otherwise create current object
                        sendDataObject(currentRangeIdx, from: offset)
                    }
                }
            } else {
                // If offset % maxLen and CRC does not match it means that the whole object needs to be sent again
                if (offset % maxLen) == 0 {
                    // currentRangeIdx won't go below 0 because offset > 0 and offset % maxLen == 0
                    currentRangeIdx -= 1
                }
                retryOrReportCrcError({
                    createDataObject(currentRangeIdx)
                })
            }
        } else {
            // If the PRNs are enabled the value must be sent to the target
            if initiator.packetReceiptNotificationParameter > 0 {
                peripheral.setPRNValue(initiator.packetReceiptNotificationParameter)
            } else {
                // Otherwise we can just start by creating the first object. PRNs were set to 0 before, to send the init packet.
                // Note: setting PRNs to 0 (disabling them) will not work!
                
                // Create the first data object
                createDataObject(currentRangeIdx)
            }
        }
    }
    
    func peripheralDidCreateDataObject() {
        logWith(.info, message: "Data object \(currentRangeIdx + 1)/\(firmwareRanges!.count) created")
        sendDataObject(currentRangeIdx)
    }
    
    func peripheralDidReceiveObject() {
        peripheral.sendCalculateChecksumCommand()
    }
    
    // MARK: - Private methods
    
    private func retryOrReportCrcError(_ operation:()->()) {
        retryCount -= 1
        if retryCount > 0 {
            logWith(.warning, message: "CRC does not match! Retrying...")
            operation()
        } else {
            logWith(.error, message: "CRC does not match!")
            error(.crcError, didOccurWithMessage: "Sending firmware failed")
        }
    }
    
    private func crcOk() {
        retryCount = MaxRetryCount
    }
    
    /**
     Resets firmware ranges and progress flags. This method should be called before sending each part of the firmware.
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
     In Secure DFU the firmware is sent as separate 'objects', where each object is at most 'maxLen' long.
     This method creates a list of ranges that will be used to send data to the peripheral, for example:
     0 ..< 4096, 4096 ..< 5000 in case the firmware was 5000 bytes long.
     */
    private func calculateFirmwareRanges(_ maxLen: Int) -> [Range<Int>] {
        var totalLength = firmware.data.count
        var ranges = [Range<Int>]()
        
        var partIdx = 0
        while (totalLength > 0) {
            var range : Range<Int>
            if totalLength > maxLen {
                totalLength -= maxLen
                range = (partIdx * maxLen) ..< maxLen + (partIdx * maxLen)
            } else {
                range = (partIdx * maxLen) ..< totalLength + (partIdx * maxLen)
                totalLength = 0
            }
            ranges.append(range)
            partIdx += 1
        }
        
        return ranges
    }
    
    /**
     Verifies if the CRC-32 of the data for byte 0 to given offset matches the given CRC value.
     - parameter data: firmware or Init packet data
     - parameter offset: number of bytes that should be used for CRC calculation
     - parameter crc: the CRC obtained from the DFU Target to be matched
     - returns: true if CRCs are identical, false otherwise
     */
    private func verifyCRC(for data: Data, andPacketOffset offset: UInt32, matches crc: UInt32) -> Bool {
        // Edge case where a different objcet might be flashed with a biger init file
        if offset > UInt32(data.count) {
            return false
        }
        // Get data form 0 up to the offset the peripheral has reproted
        let offsetData : Data = (data.subdata(in: 0 ..< Int(offset)))
        let calculatedCRC = CRC32(data: offsetData).crc
        
        // This returns true if the current data packet's CRC matches the current firmware's packet CRC
        return calculatedCRC == crc
    }
    
    /**
     Sends the Init packet starting from the given offset. This method is synchronous, however it calls 
     peripheralDidReceiveInitPacket() callback when done.
     */
    private func sendInitPacket(fromOffset offset: UInt32) {
        let initPacketLength = UInt32(firmware.initPacket!.count)
        let data = firmware.initPacket!.subdata(in: Int(offset) ..< Int(initPacketLength - offset))
        
        // Send following bytes of init packet (offset may be 0)
        peripheral.sendInitPacket(data)
    }
    
    /**
     Creates the new data object with length equal to the length of the range with given index.
     The ranges were calculated using `calculateFirmwareRanges()`.
     */
    private func createDataObject(_ rangeIdx: Int) {
        let currentRange = firmwareRanges![rangeIdx]
        peripheral.createDataObject(withLength: UInt32(currentRange.upperBound - currentRange.lowerBound))
    }
    
    /**
     This method sends the bytes from the range with given index.
     If the resumeOffset is set and equal to lower bound of the given range it will create the object instead.
     When created, a onObjectCreated() method will be called which will call this method again, now with the offset
     parameter equal nil.
     - parameter rangeIdx: index of the range to be sent. The ranges were calculated using `calculateFirmwareRanges()`.
     - parameter resumeOffset: if set, this method will send only the part of firmware from the range. The offset must
     be inside the given range.
     */
    private func sendDataObject(_ rangeIdx: Int, from resumeOffset: UInt32? = nil) {
        var aRange = firmwareRanges![rangeIdx]
        
        if let resumeOffset = resumeOffset {
            if UInt32(aRange.lowerBound) == resumeOffset {
                // We reached the end of previous object so a new one must be created
                createDataObject(rangeIdx)
                return
            }
            
            // This is a resuming object, recalculate location and size
            let newLength = aRange.lowerBound + (aRange.upperBound - aRange.lowerBound) - Int(offset!)
            aRange = Int(resumeOffset) ..< newLength + Int(resumeOffset)
        }
        
        peripheral.sendNextObject(from: aRange, of: firmware, andReportProgressTo: progressDelegate)
    }
}
