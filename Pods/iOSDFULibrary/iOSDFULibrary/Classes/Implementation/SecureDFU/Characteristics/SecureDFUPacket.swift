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
    static private let UUID = CBUUID(string: "8EC90002-F315-4F60-9FB8-838830DAEA50")
    
    static func matches(characteristic:CBCharacteristic) -> Bool {
        return characteristic.UUID.isEqual(UUID)
    }
    
    private let PacketSize = 20
    
    private var characteristic:CBCharacteristic
    private var logger:LoggerHelper
    
    /// Number of bytes of firmware already sent.
    private(set) var bytesSent = 0

    /// Current progress in percents (0-99).
    private var progress = 0
    private var startTime:CFAbsoluteTime?
    private var lastTime:CFAbsoluteTime?

    var valid:Bool {
        return characteristic.properties.contains(CBCharacteristicProperties.WriteWithoutResponse)
    }
    
    init(_ characteristic:CBCharacteristic, _ logger:LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    func sendInitPacket(initPacketData : NSData){
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Data may be sent in up-to-20-bytes packets
        var offset = 0
        var bytesToSend = initPacketData.length
        
        repeat {

            let packetLength = min(bytesToSend, PacketSize)
            let packet = initPacketData.subdataWithRange(NSRange(location: offset, length: packetLength))
            
            logger.v("Writing to characteristic \(SecureDFUPacket.UUID.UUIDString)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), forCharacteristic: \(SecureDFUPacket.UUID.UUIDString), type: WithoutResponse)")
            peripheral.writeValue(packet, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }
    
    func resumeFromOffset(anOffset : UInt32) {
        self.bytesSent = Int(anOffset)
        startTime = CFAbsoluteTimeGetCurrent()
        lastTime = startTime
    }

    /**
     Sends data over packet characteristic
    */
    
    func sendData(withPRN aPRNVaule:UInt16, andRange aRange: NSRange, inFirmware aFirmware : DFUFirmware, andProgressHandler aProgressHandler : DFUProgressDelegate?, andCompletion aCompletion: SDFUCallback) {
        let peripheral   = characteristic.service.peripheral
        let aData        = aFirmware.data.subdataWithRange(aRange)
        let bytesTotal   = aData.length
        let totalPackets = (bytesTotal + PacketSize - 1) / PacketSize
        let packetsSent  = (bytesSent + PacketSize - 1) / PacketSize
        let packetsLeft  = totalPackets - packetsSent

        // Calculate how many packets should be sent before EOF or next receipt notification
        var packetsToSendNow = min(Int(aPRNVaule), packetsLeft)
        
        if aPRNVaule == 0 {
            packetsToSendNow = totalPackets
        }
        
        // Initialize timers
        if bytesSent == 0 {
            startTime = CFAbsoluteTimeGetCurrent()
            lastTime = startTime
        }
        
        while packetsToSendNow > 0 {
            let bytesLeft = bytesTotal - bytesSent
            let packetLength = min(bytesLeft, PacketSize)
            let packet = aData.subdataWithRange(NSRange(location: bytesSent, length: packetLength))
            peripheral.writeValue(packet, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate current transfer speed in bytes per second
            let now = CFAbsoluteTimeGetCurrent()
            lastTime = now
            
            // Calculate progress for current chunk, this is not presented to progress delegate
            let currentProgress = (bytesSent * 100 / bytesTotal)
            // Calculate the total progress of the firmware, presented to the delegate
            let totalProgress = (aRange.location + bytesSent) * 100 / (aFirmware.data).length
            
            // Notify progress listener only if current progress has increased since last time
            if currentProgress > progress {
                let avgSpeed = Double(bytesSent) / (now - startTime!)
                // Calculate current transfer speed in bytes per second
                let now = CFAbsoluteTimeGetCurrent()
                let currentSpeed = Double(packetLength) / (now - lastTime!)
                lastTime = now
                
                dispatch_async(dispatch_get_main_queue(), {
                    //Notify handler of current chunk progress
                    //to start sending next chunk
                    if currentProgress == 100 {
                        aCompletion(responseData: nil)
                    }
                    
                    //Notify progrsess delegate of overall progress
                    dispatch_async(dispatch_get_main_queue(), {
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
