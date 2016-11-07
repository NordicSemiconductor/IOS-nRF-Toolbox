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

internal class SecureDFUExecutor : SecureDFUPeripheralDelegate {

    /// The DFU Service Initiator instance that was used to start the service.
    fileprivate let initiator:SecureDFUServiceInitiator
    
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
    fileprivate var peripheral:SecureDFUPeripheral

    /// The firmware to be sent over-the-air
    fileprivate var firmware        : DFUFirmware
    fileprivate var firmwareRanges  : [Range<Int>]?
    fileprivate var currentRangeIdx : Int?
    fileprivate var error           : (error:DFUError, message:String)?

    fileprivate var maxLen          : UInt32?
    fileprivate var offset          : UInt32?
    fileprivate var crc             : UInt32?

    fileprivate var initPacketSent  : Bool = false
    fileprivate var firmwareSent    : Bool = false
    fileprivate var sendingFirmware : Bool = false
    fileprivate var isResuming      : Bool = false
    
    // MARK: - Initialization
    init(_ initiator:SecureDFUServiceInitiator) {
        self.initiator = initiator
        self.firmware = initiator.file!
        self.peripheral = SecureDFUPeripheral(initiator)
    }

    // MARK: - DFU Controller methods
    func start() {
        self.error = nil
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.connecting)
        })
        peripheral.delegate = self
        peripheral.connect()
        self.initiator.logger?.logWith(.verbose, message: "Connecting to Secure DFU peripheral \(peripheral)")
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

    // MARK: - Secure DFU Peripheral Delegate methods
    func onAborted() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.aborted)
        })
        // Release the cyclic reference
        peripheral.destroy()
    }

    func onDeviceReady() {
        //All services/characteristics have been discovered, Start by reading object info
        //to get the maximum write size.
        self.firmwareSent    = false
        self.sendingFirmware = false
        self.initPacketSent  = false

        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.starting)
        })
        peripheral.enableControlPoint()
    }

    func resetFirmwareRanges() {
        self.currentRangeIdx = 0
        self.firmwareRanges = nil
    }

    func calculateFirmwareRanges() -> [Range<Int>]{
        var totalLength = self.firmware.data.count
        let currentMaxLen = Int(maxLen!)
        var ranges = [Range<Int>]()

        var partIdx = 0
        while(totalLength > 0) {
            var chunkRange : Range<Int>?
            if totalLength > currentMaxLen {
                totalLength -= currentMaxLen
                //TODO: Verify this is correct
                chunkRange = (partIdx*currentMaxLen)..<currentMaxLen + (partIdx*currentMaxLen)
            } else {
                //TODO: Verify this is correct
                chunkRange = (partIdx*currentMaxLen)..<totalLength + (partIdx*currentMaxLen)
                //chunkRange = NSRange(location:partIdx*currentMaxLen, length:totalLength)
                totalLength = 0
            }
            ranges.append(chunkRange!)
            partIdx += 1
        }

        return ranges
    }

    func onControlPointEnabled() {
        peripheral.ReadObjectInfoCommand()
    }
    
    func verifyDataCRC(fordata data : Data, andPacketOffset anOffset : UInt32, andperipheralCRC aCRC : UInt32) -> Bool {
        
        //Edge case where a different objcet might be flashed with a biger init file
        if anOffset > UInt32(data.count) {
            return false
        }
        //get data form 0 up to the offset the peripheral has reproted
        let offsetData : Data = (data.subdata(in: 0..<Int(anOffset)))
        let calculatedCRC = CRC32(data: offsetData).crc

        //This returns true if the current data packet's CRC matches the current firmware's packet CRC
        return calculatedCRC == aCRC
    }
    
    func resumeSendInitpacket(atOffset anOffset : UInt32) {
        
        let initPacketLength = UInt32((self.firmware.initPacket?.count)!)
        
        //Log how much of the packet has been already sent
        let sentPercentage = Int(Double(anOffset) / Double(initPacketLength) * 100.0)
        self.initiator.logger?.logWith(.info, message: String(format:"%d%% of init packet sent, resuming!", sentPercentage))
        //get remaining data to send
        //TODO: verify this is correct
        let data = self.firmware.initPacket?.subdata(in: Int(anOffset)..<Int(initPacketLength - anOffset))
        
        //Send data
        self.peripheral.sendInitpacket(data!)
    }
    
    func objectInfoReadCommandCompleted(_ maxLen : UInt32, offset : UInt32, crc :UInt32 ) {
        self.maxLen = maxLen
        self.offset = offset
        self.crc = crc

        if self.offset! > 0 && self.crc! > 0 {
            isResuming = true
            let match = self.verifyDataCRC(fordata: self.firmware.initPacket! as Data, andPacketOffset: offset, andperipheralCRC: crc)
            if match == true {
                //Resume Init
                if self.offset! < UInt32((self.firmware.initPacket?.count)!) {
                    self.initiator.logger?.logWith(.info, message: "Init packet was incomplete, resuming..")
                    self.resumeSendInitpacket(atOffset: offset)
                }else{
                    self.initPacketSent  = true
                    self.firmwareSent    = false
                    self.sendingFirmware = false
                    self.initiator.logger?.logWith(.info, message: "Init packet was complete, verify data object")
                    peripheral.ReadObjectInfoData()
                }
            }else{
                //Start new flash, we either are flashing a different firmware
                //or we are resuming from a BL/SD + App and need to start all over again.
                self.initiator.logger?.logWith(.info, message: "firmare init packet doesn't match, will overwrite and start again")
                self.startDFUIgnoringState()
            }
        }else{
            peripheral.createObjectCommand(UInt32((self.firmware.initPacket?.count)!))
        }
    }
    
    func startDFUIgnoringState() {
        self.initPacketSent = false
        self.firmwareSent = false
        self.sendingFirmware = false
        self.isResuming = false //We're no longer resuming, but starting from scratch.
        peripheral.createObjectCommand(UInt32((self.firmware.initPacket?.count)!))
    }
    
    func objectInfoReadDataCompleted(_ maxLen : UInt32, offset : UInt32, crc :UInt32 ) {

        self.maxLen = maxLen
        self.offset = offset
        self.crc    = crc

        //This is the intial state, if ranges aren't set, assume this is the first
        //or the only stage in the DFU process
        if self.currentRangeIdx == nil {
            //Split firmware into smaller chunks of maxlen, if firmware is bigger than maxlen
            self.firmwareRanges   = self.calculateFirmwareRanges()
            self.currentRangeIdx = 0
        }

        if isResuming == true {
            let match = self.verifyDataCRC(fordata: self.firmware.data as Data, andPacketOffset: self.offset!, andperipheralCRC: self.crc!)

            if match == true {
                let completion = Int(Double(self.offset!) / Double(self.firmware.data.count) * 100)
                if Double(self.offset!) == Double(self.firmware.data.count) {
                    sendingFirmware = false
                    firmwareSent    = true
                    self.initiator.logger?.logWith(.info, message: "Data object fully sent, but not executed yet.")
                    self.peripheral.sendExecuteCommand()
                }else{
                    DispatchQueue.main.async(execute: {
                        self.delegate?.didStateChangedTo(DFUState.uploading)
                    })
                    self.initiator.logger?.logWith(.info, message: String(format:"Data object info CRC matches, resuming from %d%%..",completion))
                    peripheral.setPRNValue(self.initiator.packetReceiptNotificationParameter)
                }
            } else {
                self.initiator.logger?.logWith(.error, message: "Data object CRC does not match")
                self.initiator.logger?.logWith(.error, message: "Will fallback to starting from scratch")
                self.startDFUIgnoringState()
            }
        } else {
            DispatchQueue.main.async(execute: {
                self.delegate?.didStateChangedTo(DFUState.uploading)
            })
            
            //Start sending firmware in chunks
            sendingFirmware = true
            self.createObjectDataForCurrentChunk()
       }
    }

    func createObjectDataForCurrentChunk() {
        let currentRange = self.firmwareRanges![self.currentRangeIdx!]
        self.initiator.logger?.logWith(.info, message: "Current Object data chunk size = \(currentRange.upperBound - currentRange.lowerBound)")

        peripheral.createObjectData(withLength: UInt32(currentRange.upperBound - currentRange.lowerBound))
    }
    
    func firmwareSendComplete() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.validating)
        })
        self.firmwareSent    = true
        self.sendingFirmware = false
        peripheral.sendCalculateChecksumCommand()
        
    }

    func firmwareChunkSendcomplete() {
        self.initiator.logger?.logWith(.application, message: "Object data chunk sent")
        peripheral.sendCalculateChecksumCommand()
        
    }

    func objectCreateDataCompleted(_ data: Data?) {
        self.initiator.logger?.logWith(.info, message: "Object created, sending data for chunk \(self.currentRangeIdx!)")
        sendCurrentChunk()
    }

    func sendCurrentChunk(_ resumeOffset : UInt32 = 0){
        var aRange = firmwareRanges![currentRangeIdx!]
        if self.isResuming && resumeOffset > 0 {
            //This is a resuming chunk, recalculate location and size
            let newLength = aRange.lowerBound + (aRange.upperBound - aRange.lowerBound) - Int(self.offset!)
            aRange = Int(resumeOffset)..<newLength + Int(resumeOffset)
            
            if UInt32(aRange.lowerBound) == resumeOffset {
                self.createObjectDataForCurrentChunk()
                return
            }
        }

        peripheral.sendFirmwareChunk(self.firmware, andChunkRange: aRange, andPacketCount: self.initiator.packetReceiptNotificationParameter, andProgressDelegate: self.progressDelegate!)
    }

    func objectCreateCommandCompleted(_ data: Data?) {
        peripheral.setPRNValue(0) //disable for first time while we write Init file
    }

    func setPRNValueCompleted() {
        if initPacketSent == false {
            DispatchQueue.main.async(execute: {
                self.delegate?.didStateChangedTo(DFUState.enablingDfuMode)
            })
            peripheral.sendInitpacket(self.firmware.initPacket!)
        }else if firmwareSent == false{
            if isResuming == false {
                peripheral.ReadObjectInfoData()
            } else {
                //Resume data from a given chunk offset
                self.currentRangeIdx = 0
                for chunkRange in self.firmwareRanges! {
                    if NSLocationInRange(Int(self.offset!), NSRange(chunkRange)) {
                        break
                    }
                    self.currentRangeIdx! += 1
                }
                DispatchQueue.main.async(execute: {
                    self.delegate?.didStateChangedTo(DFUState.uploading)
                })
                //Now we can resume from the current given offset
                self.sendingFirmware = true
                self.sendCurrentChunk(self.offset!)
            }
        }
    }
    
    func initPacketSendCompleted() {
        self.initPacketSent = true
        peripheral.sendCalculateChecksumCommand()
    }

    func calculateChecksumCompleted(_ offset: UInt32, CRC: UInt32) {

        self.crc    = CRC
        self.offset = offset
        //Firmware is still being sent!
        if sendingFirmware == true {
            //verify CRC
            if verifyDataCRC(fordata: self.firmware.data, andPacketOffset: self.offset!, andperipheralCRC: self.crc!) {
                self.initiator.logger?.logWith(.info, message: "Data checksum matches.")
                peripheral.sendExecuteCommand()
                return
            }else{
                self.initiator.logger?.logWith(.error, message: "Data checksum mismatch!")
                return
            }
        }

        if initPacketSent == true && firmwareSent == false {
            if offset == UInt32((firmware.initPacket?.count)!) {
                if verifyDataCRC(fordata: self.firmware.initPacket!, andPacketOffset: UInt32((self.firmware.initPacket?.count)!), andperipheralCRC: self.crc!) {
                    self.initiator.logger?.logWith(.info, message: "Init packet checksum match, sending execute command")
                    peripheral.sendExecuteCommand()
                }else{
                    self.initiator.logger?.logWith(.error, message: "Init packet checksum mismatch")
                }
            } else {
                self.initiator.logger?.logWith(.error, message: "Offset doesn't match packet size!")
            }
        }
    }

    func executeCommandCompleted() {
        if sendingFirmware && !firmwareSent {
            if(currentRangeIdx! < (firmwareRanges?.count)! - 1) {
                currentRangeIdx! += 1
                createObjectDataForCurrentChunk()
                return
            } else {
                sendingFirmware = true
                firmwareSent    = true
            }
        }
        
        if initPacketSent == true && firmwareSent == false {
            peripheral.setPRNValue(self.initiator.packetReceiptNotificationParameter)
        } else {
            self.firmwareSent    = false
            self.sendingFirmware = false
            self.initPacketSent  = false

            //Reset ranges
            if self.firmware.hasNextPart() {
                //Prepare next part for sending
                self.resetFirmwareRanges()
                self.firmware.switchToNextPart()
                //Get new ranges for new part
                self.firmwareRanges  = self.calculateFirmwareRanges()
                self.initPacketSent  = false
                self.sendingFirmware = false
                self.firmwareSent    = false
                self.isResuming      = false
                //setting the resetting state flag so we don't assume this is an error
                peripheral.isResetting = true
                peripheral.disconnect()
                peripheral.switchToNewPeripheralAndConnect(initiator.peripheralSelector)
            } else {
                //This is not a reset disconnection
                peripheral.isResetting = false
                self.firmwareSent       = true
                delegate?.didStateChangedTo(.completed)
                peripheral.disconnect()
            }
        }
    }

    func didDeviceFailToConnect() {
        self.initiator.logger?.logWith(.error, message: "Failed to connect")
        self.delegate?.didErrorOccur(.failedToConnect, withMessage: "Failed to connect")
        self.delegate?.didStateChangedTo(.failed)
    }
    
    func peripheralDisconnected() {
        if peripheral.isResetting {
            self.initiator.logger?.logWith(.application, message: "Peripheral is now resetting, operation will resume after restart...")
            self.delegate?.didStateChangedTo(.starting)
        }else if self.firmwareSent {
            self.initiator.logger?.logWith(.application, message: "Operation completed, peripheral has been disconnected")
            self.delegate?.didStateChangedTo(.completed)

        }else{
            self.initiator.logger?.logWith(.application, message: "Operation Aborted by user, peripheral has been disconnected")
            self.delegate?.didStateChangedTo(.aborted)
        }
    }
    
    func peripheralDisconnected(withError anError : NSError) {
        self.initiator.logger?.logWith(.error, message: anError.description)
        self.delegate?.didErrorOccur(.deviceDisconnected, withMessage: anError.localizedDescription)
        self.delegate?.didStateChangedTo(.failed)
    }
    
    func onErrorOccured(withError anError:SecureDFUError, andMessage aMessage:String) {
        self.initiator.logger?.logWith(.error, message: aMessage)
        self.delegate?.didErrorOccur(.deviceDisconnected, withMessage: aMessage)

        //Temp fix for sig mismatch
        //TODO: This is a quick solution until we have a unified (S)DFUError enum
        if anError == .signatureMismatch {
            self.delegate?.didStateChangedTo(.signatureMismatch)
        }else{
            self.delegate?.didStateChangedTo(.failed)
        }
        peripheral.disconnect()
    }
}
