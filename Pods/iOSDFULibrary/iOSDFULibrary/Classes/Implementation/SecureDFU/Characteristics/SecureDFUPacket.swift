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

internal class SecureDFUPacket {
    static fileprivate let UUID = CBUUID(string: "8EC90002-F315-4F60-9FB8-838830DAEA50")
    
    static func matches(_ characteristic:CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    fileprivate let PacketSize = 20
    
    fileprivate var characteristic:CBCharacteristic
    fileprivate var logger:LoggerHelper
    
    /// Number of bytes of firmware already sent.
    fileprivate(set) var bytesSent = 0

    /// Current progress in percents (0-99).
    fileprivate var progress = 0
    fileprivate var startTime:CFAbsoluteTime?
    fileprivate var lastTime:CFAbsoluteTime?

    var valid:Bool {
        return characteristic.properties.contains(CBCharacteristicProperties.writeWithoutResponse)
    }
    
    init(_ characteristic:CBCharacteristic, _ logger:LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    func sendInitPacket(_ initPacketData : Data){
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Data may be sent in up-to-20-bytes packets
        var offset = 0
        var bytesToSend = initPacketData.count
        
        repeat {

            let packetLength = min(bytesToSend, PacketSize)
            let packet = initPacketData.subdata(in: offset..<offset + packetLength)
            
            logger.v("Writing to characteristic \(SecureDFUPacket.UUID.uuidString)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), forCharacteristic: \(SecureDFUPacket.UUID.uuidString), type: WithoutResponse)")
            peripheral.writeValue(packet, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }
    
    func resumeFromOffset(_ anOffset : UInt32) {
        self.bytesSent = Int(anOffset)
        startTime = CFAbsoluteTimeGetCurrent()
        lastTime = startTime
    }

    /**
     Sends data over packet characteristic
    */
    
    func sendData(withPRN aPRNVaule:UInt16, andRange aRange: Range<Int>, inFirmware aFirmware : DFUFirmware, andProgressHandler aProgressHandler : DFUProgressDelegate?, andCompletion aCompletion: @escaping SDFUCallback) {
        let peripheral   = characteristic.service.peripheral
        let aData        = aFirmware.data.subdata(in: aRange)
        let bytesTotal   = aData.count
        let totalPackets = (bytesTotal + PacketSize - 1) / PacketSize
        let packetsSent  = (bytesSent + PacketSize - 1) / PacketSize
        let packetsLeft  = totalPackets - packetsSent

        // Calculate how many packets should be sent before EOF or next receipt notification
        var packetsToSendNow = min(Int(aPRNVaule), packetsLeft)
        
        if aPRNVaule == 0 {
            packetsToSendNow = totalPackets
        }
        
        // This is called when we no longer have data to send (PRN received after the whole object was sent)
        // Fixes issue IDFU-9
        if packetsToSendNow == 0 {
            aCompletion(nil)
            return
        }

        // Initialize timers
        if bytesSent == 0 {
            startTime = CFAbsoluteTimeGetCurrent()
            lastTime = startTime
        }
        
        let originalPacketsToSendNow = packetsToSendNow
        while packetsToSendNow > 0 {
            let bytesLeft = bytesTotal - bytesSent
            let packetLength = min(bytesLeft, PacketSize)
            let range:Range<Int> = bytesSent..<(packetLength+bytesSent)
            let packet = aData.subdata(in: range)
            peripheral.writeValue(packet, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate current transfer speed in bytes per second
            let now = CFAbsoluteTimeGetCurrent()
            lastTime = now
            
            // Calculate progress for current chunk, this is not presented to progress delegate
            let currentProgress = (bytesSent * 100 / bytesTotal)
            // Calculate the total progress of the firmware, presented to the delegate
            let totalProgress = (aRange.lowerBound + bytesSent) * 100 / (aFirmware.data).count
            
            // Notify progress listener only if current progress has increased since last time
            if currentProgress > progress {
                let avgSpeed = Double(bytesSent) / (now - startTime!)
                // Calculate current transfer speed in bytes per second
                let now = CFAbsoluteTimeGetCurrent()
                let currentSpeed = Double(packetLength) / (now - lastTime!)
                lastTime = now
                
                DispatchQueue.main.async(execute: {
                    // Notify handler of current chunk progress
                    // to start sending next chunk
                    if currentProgress == 100 {
                        if aPRNVaule == 0 || originalPacketsToSendNow < Int(aPRNVaule) {
                            aCompletion(nil)
                        } else {
                            // The whole object has been sent but the DFU target will
                            // send a PRN notification as expected.
                            // The sendData method will be called again
                            // with packetsLeft = 0
                            
                            // Do nothing
                        }
                    }
                
                    // Notify progrsess delegate of overall progress
                    DispatchQueue.main.async(execute: {
                        aProgressHandler?.onUploadProgress(aFirmware.currentPart,
                            totalParts: aFirmware.parts,
                            progress: totalProgress,
                            currentSpeedBytesPerSecond:currentSpeed,
                            avgSpeedBytesPerSecond:avgSpeed)
                    })
                    
                })
                self.progress = currentProgress
            }
        }
    }

    func resetCounters() {
        self.bytesSent = 0
        self.progress  = 0
    }
}
