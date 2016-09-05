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
    private let initiator:SecureDFUServiceInitiator
    
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
    private var peripheral:SecureDFUPeripheral

    /// The firmware to be sent over-the-air
    private var firmware        : DFUFirmware
    private var firmwareRanges  : [NSRange]?
    private var currentRangeIdx : Int?
    private var error           : (error:DFUError, message:String)?

    private var maxLen          : UInt32?
    private var offset          : UInt32?
    private var crc             : UInt32?

    private var initPacketSent  : Bool = false
    private var firmwareSent    : Bool = false
    private var sendingFirmware : Bool = false
    private var isResuming      : Bool = false

    // MARK: - Initialization
    init(_ initiator:SecureDFUServiceInitiator) {
        self.initiator = initiator
        self.firmware = initiator.file!
        self.peripheral = SecureDFUPeripheral(initiator)
    }

    // MARK: - DFU Controller methods
    func start() {
        self.error = nil
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(DFUState.Connecting)
        })
        peripheral.delegate = self
        peripheral.connect()
        self.initiator.logger?.logWith(.Verbose, message: "Connecting to Secure DFU peripheral \(peripheral)")
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
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(DFUState.Aborted)
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

        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(DFUState.Starting)
        })
        peripheral.enableControlPoint()
    }

    func resetFirmwareRanges() {
        self.currentRangeIdx = 0
        self.firmwareRanges = nil
    }

    func calculateFirmwareRanges() -> [NSRange]{
        var totalLength = self.firmware.data.length
        let currentMaxLen = Int(maxLen!)
        var ranges = [NSRange]()
        
        var partIdx = 0
        while(totalLength > 0) {
            var chunkRange : NSRange?
            if totalLength > currentMaxLen {
                totalLength -= currentMaxLen
                chunkRange = NSRange(location:partIdx*currentMaxLen, length:currentMaxLen)
            } else {
                chunkRange = NSRange(location:partIdx*currentMaxLen, length:totalLength)
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
    
    func verifyDataCRC(fordata data : NSData, andPacketOffset anOffset : UInt32, andperipheralCRC aCRC : UInt32) -> Bool {
        //get data form 0 up to the offset the peripheral has reproted
        let offsetData : NSData = (data.subdataWithRange(NSRange(location: 0, length: Int(anOffset))))
        let calculatedCRC = CRC32(data: offsetData).crc
        
        //This returns true if the current data packet's CRC matches the current firmware's packet CRC
        return calculatedCRC == aCRC
    }
    
    func resumeSendInitpacket(atOffset anOffset : UInt32) {
        
        let initPacketLength = UInt32((self.firmware.initPacket?.length)!)
        
        //Log how much of the packet has been already sent
        let sentPercentage = Int(Double(anOffset) / Double(initPacketLength) * 100.0)
        self.initiator.logger?.logWith(.Info, message: String(format:"%d%% of init packet sent, resuming!", sentPercentage))
        //get remaining data to send
        let data = self.firmware.initPacket?.subdataWithRange(NSRange(location: Int(anOffset), length: Int(initPacketLength - anOffset)))
        
        //Send data
        self.peripheral.sendInitpacket(data!)
    }
    
    func objectInfoReadCommandCompleted(let maxLen : UInt32, offset : UInt32, crc :UInt32 ) {
        self.maxLen = maxLen
        self.offset = offset
        self.crc = crc

        if self.offset > 0 && self.crc > 0 {
            isResuming = true
            let match = self.verifyDataCRC(fordata: self.firmware.initPacket!, andPacketOffset: offset, andperipheralCRC: crc)
            if match == true {
                //Resume Init
                if self.offset < UInt32((self.firmware.initPacket?.length)!) {
                    self.initiator.logger?.logWith(.Info, message: "Init packet was incomplete, resuming..")
                    self.resumeSendInitpacket(atOffset: offset)
                }else{
                    self.initPacketSent  = true
                    self.firmwareSent    = false
                    self.sendingFirmware = false
                    self.initiator.logger?.logWith(.Info, message: "Init packet was complete, verify data object")
                    peripheral.ReadObjectInfoData()
                }
            }else{
                //Start new flash, we either are flashing a different firmware
                //or we are resuming from a BL/SD + App and need to start all over again.
                self.initiator.logger?.logWith(.Info, message: "firmare init packet doesn't match, will overwrite and start again")
                self.initPacketSent = false
                self.firmwareSent = false
                self.sendingFirmware = false
                self.isResuming = false //We're no longer resuming, but starting from scratch.
                peripheral.createObjectCommand(UInt32((self.firmware.initPacket?.length)!))
            }
        }else{
            peripheral.createObjectCommand(UInt32((self.firmware.initPacket?.length)!))
        }
    }
    
    func objectInfoReadDataCompleted(maxLen : UInt32, offset : UInt32, crc :UInt32 ) {

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
            let match = self.verifyDataCRC(fordata: self.firmware.data, andPacketOffset: self.offset!, andperipheralCRC: self.crc!)

            if match == true {
                let completion = Int(Double(self.offset!) / Double(self.firmware.data.length) * 100)
                if Double(self.offset!) == Double(self.firmware.data.length) {
                    sendingFirmware = false
                    firmwareSent    = true
                    self.initiator.logger?.logWith(.Info, message: "Data object fully sent, but not executed yet.")
                    self.peripheral.sendExecuteCommand()
                }else{
                    dispatch_async(dispatch_get_main_queue(), {
                        self.delegate?.didStateChangedTo(DFUState.Uploading)
                    })
                    self.initiator.logger?.logWith(.Info, message: String(format:"Data object info CRC matches, resuming from %d%%..",completion))
                    peripheral.setPRNValue(12)
                }
            } else {
                self.initiator.logger?.logWith(.Error, message: "Data object does not match")
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.didStateChangedTo(DFUState.Uploading)
            })
            
            //Start sending firmware in chunks
            sendingFirmware = true
            self.createObjectDataForCurrentChunk()
       }
    }

    func createObjectDataForCurrentChunk() {
        let currentRange = self.firmwareRanges![self.currentRangeIdx!]
        self.initiator.logger?.logWith(.Info, message: "current firmware chunk length = \(currentRange.length)")

        peripheral.createObjectData(withLength: UInt32(currentRange.length))
    }
    
    func firmwareSendComplete() {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(DFUState.Validating)
        })
        self.firmwareSent    = true
        self.sendingFirmware = false
        peripheral.sendCalculateChecksumCommand()
    }

    func firmwareChunkSendcomplete() {
        self.initiator.logger?.logWith(.Application, message: "Chunk sent!")
        peripheral.sendCalculateChecksumCommand()
    }

    func objectCreateDataCompleted(data: NSData?) {
        self.initiator.logger?.logWith(.Info, message: "Object created, sending data for chunk \(self.currentRangeIdx!)")
        sendCurrentChunk()
    }

    func sendCurrentChunk(let resumeOffset : UInt32 = 0){
        var aRange = firmwareRanges![currentRangeIdx!]
        if self.isResuming && resumeOffset > 0 {

            //This is a resuming chunk, recalculate location and size
            let newLength = aRange.location + aRange.length - Int(self.offset!)
            aRange.location = Int(resumeOffset)
            aRange.length   = newLength
        }
        peripheral.sendFirmwareChunk(self.firmware, andChunkRange: aRange, andPacketCount: 12, andProgressDelegate: self.progressDelegate!)
    }

    func objectCreateCommandCompleted(data: NSData?) {
        peripheral.setPRNValue(0) //disable for first time while we write Init file
    }

    func setPRNValueCompleted() {
        if initPacketSent == false {
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.didStateChangedTo(DFUState.EnablingDfuMode)
            })
            peripheral.sendInitpacket(self.firmware.initPacket!)
        }else if firmwareSent == false{
            if isResuming == false {
                peripheral.ReadObjectInfoData()
            } else {
                //Resume data from a given chunk offset
                self.currentRangeIdx = 0
                for chunkRange in self.firmwareRanges! {
                    if NSLocationInRange(Int(self.offset!), chunkRange) {
                        break
                    }
                    self.currentRangeIdx! += 1
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.delegate?.didStateChangedTo(DFUState.Uploading)
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

    func calculateChecksumCompleted(offset: UInt32, CRC: UInt32) {
        self.crc    = CRC
        self.offset = offset
        
        //Firmware is still being sent!
        if sendingFirmware == true {
            //verify CRC
            let chunkData = self.firmware.data.subdataWithRange(NSRange(location: 0, length:Int(self.offset!)))
            let crc = CRC32.init(data: chunkData).crc
            if self.crc == crc {
                self.initiator.logger?.logWith(.Info, message: "Chunk CRC matches, exetuce!")
                peripheral.sendExecuteCommand()
                return
            }else{
                self.initiator.logger?.logWith(.Error, message: "Chunk CRC mismatch!")
                return
            }
        }

        if initPacketSent == true && firmwareSent == false {
            if offset == UInt32((firmware.initPacket?.length)!) {
                let calculatedCRC = CRC32(data: self.firmware.initPacket!).crc
                if calculatedCRC == self.crc {
                    self.initiator.logger?.logWith(.Info, message: "CRC match, send execute command")
                    peripheral.sendExecuteCommand()
                }else{
                    self.initiator.logger?.logWith(.Error, message: "CRC for init packet does not match, local = \(calculatedCRC), reported = \(self.crc!)")
                }
            } else {
                self.initiator.logger?.logWith(.Error, message: "Offset doesn't match packet size!")
            }
        }
    }

    func executeCommandCompleted() {
        if sendingFirmware && !firmwareSent {
            if(currentRangeIdx! < (firmwareRanges?.count)! - 1) {
                currentRangeIdx! += 1
                createObjectDataForCurrentChunk()
                return
            }else{
                sendingFirmware = false
                firmwareSent    = true
            }
        }
        
        if initPacketSent == true && firmwareSent == false {
            peripheral.setPRNValue(12) //Enable PRN at 12 packets
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
                delegate?.didStateChangedTo(.Completed)
                peripheral.disconnect()
            }
        }
    }

    func didDeviceFailToConnect() {
        self.initiator.logger?.logWith(.Error, message: "Failed to connect")
        self.delegate?.didErrorOccur(.FailedToConnect, withMessage: "Failed to connect")
        self.delegate?.didStateChangedTo(.Failed)
    }
    
    func peripheralDisconnected() {
        if peripheral.isResetting {
            self.initiator.logger?.logWith(.Application, message: "Peripheral is now resetting, operation will resume after restart...")
            self.delegate?.didStateChangedTo(.Starting)
        }else if self.firmwareSent {
            self.initiator.logger?.logWith(.Application, message: "Operation completed, peripheral has been disconnected")
            self.delegate?.didStateChangedTo(.Completed)

        }else{
            self.initiator.logger?.logWith(.Application, message: "Operation Aborted by user, peripheral has been disconnected")
            self.delegate?.didStateChangedTo(.Aborted)
        }
    }
    
    func peripheralDisconnected(withError anError : NSError) {
        self.initiator.logger?.logWith(.Error, message: anError.description)
        self.delegate?.didErrorOccur(.DeviceDisconnected, withMessage: anError.localizedDescription)
        self.delegate?.didStateChangedTo(.Failed)
    }
    
    func onErrorOccured(withError anError:SecureDFUError, andMessage aMessage:String) {
        self.initiator.logger?.logWith(.Error, message: aMessage)
        self.delegate?.didErrorOccur(.DeviceDisconnected, withMessage: aMessage)

        //Temp fix for sig mismatch
        //TODO: This is a quick solution until we have a unified (S)DFUError enum
        if anError == .SignatureMismatch {
            self.delegate?.didStateChangedTo(.SignatureMismatch)
        }else{
            self.delegate?.didStateChangedTo(.Failed)
        }
        peripheral.disconnect()
    }
}
