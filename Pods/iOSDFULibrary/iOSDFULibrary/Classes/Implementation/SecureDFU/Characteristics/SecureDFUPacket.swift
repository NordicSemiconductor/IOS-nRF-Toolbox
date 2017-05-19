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
    
    static func matches(_ characteristic: CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    private let PacketSize: UInt32 = 20
    
    private var characteristic: CBCharacteristic
    private var logger: LoggerHelper
    
    /// Number of bytes of firmware already sent.
    private(set) var bytesSent: UInt32 = 0
    /// Number of bytes sent at the last progress notification. This value is used to calculate the current speed.
    private var totalBytesSentSinceProgessNotification: UInt32 = 0
    private var totalBytesSentWhenDfuStarted: UInt32 = 0

    /// Current progress in percents (0-99).
    private var progress:  UInt8 = 0
    private var startTime: CFAbsoluteTime?
    private var lastTime:  CFAbsoluteTime?

    internal var valid: Bool {
        return characteristic.properties.contains(.writeWithoutResponse)
    }
    
    init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    
    func sendInitPacket(_ initPacketData : Data){
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Data may be sent in up-to-20-bytes packets
        var offset: UInt32 = 0
        var bytesToSend = UInt32(initPacketData.count)
        
        repeat {
            let packetLength = min(bytesToSend, PacketSize)
            let packet = initPacketData.subdata(in: Int(offset) ..< Int(offset + packetLength))
            
            logger.v("Writing to characteristic \(characteristic.uuid.uuidString)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), for: \(characteristic.uuid.uuidString), type: .withoutResponse)")
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }

    /**
     Sends a given range of data from given firmware over DFU Packet characteristic. If the whole object is
     completed the completition callback will be called.
     */
    func sendNext(_ aPRNValue: UInt16, bytesFrom aRange: Range<Int>, of aFirmware : DFUFirmware,
                  andReportProgressTo aProgressDelegate : DFUProgressDelegate?, andCompletionTo aCompletion: @escaping Callback) {
        let peripheral          = characteristic.service.peripheral
        let objectData          = aFirmware.data.subdata(in: aRange)
        let objectSizeInBytes   = UInt32(objectData.count)
        let objectSizeInPackets = (objectSizeInBytes + PacketSize - 1) / PacketSize
        let packetsSent         = (bytesSent + PacketSize - 1) / PacketSize
        let packetsLeft         = objectSizeInPackets - packetsSent

        // Calculate how many packets should be sent before EOF or next receipt notification
        var packetsToSendNow = min(UInt32(aPRNValue), packetsLeft)
        
        if aPRNValue == 0 {
            packetsToSendNow = objectSizeInPackets
        }
        
        // This is called when we no longer have data to send (PRN received after the whole object was sent)
        // Fixes issue IDFU-9
        if packetsToSendNow == 0 {
            aCompletion()
            return
        }

        // Initialize timers
        if startTime == nil {
            startTime = CFAbsoluteTimeGetCurrent()
            lastTime = startTime
            totalBytesSentWhenDfuStarted = UInt32(aRange.lowerBound)
            totalBytesSentSinceProgessNotification = totalBytesSentWhenDfuStarted
            
            // Notify progress delegate that upload has started (0%)
            DispatchQueue.main.async(execute: {
                aProgressDelegate?.dfuProgressDidChange(
                    for:   aFirmware.currentPart,
                    outOf: aFirmware.parts,
                    to:     0,
                    currentSpeedBytesPerSecond: 0.0,
                    avgSpeedBytesPerSecond:     0.0)
            })
        }
        
        let originalPacketsToSendNow = packetsToSendNow
        while packetsToSendNow > 0 {
            let bytesLeft = objectSizeInBytes - bytesSent
            let packetLength = min(bytesLeft, PacketSize)
            let packet = objectData.subdata(in: Int(bytesSent) ..< Int(packetLength + bytesSent))
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate the total progress of the firmware, presented to the delegate
            let totalBytesSent = UInt32(aRange.lowerBound) + bytesSent
            let totalProgress = UInt8(totalBytesSent * 100 / UInt32(aFirmware.data.count))
            
            // Notify progress listener only if current progress has increased since last time
            if totalProgress > progress {
                // Calculate current transfer speed in bytes per second
                let now = CFAbsoluteTimeGetCurrent()
                let currentSpeed = Double(totalBytesSent - totalBytesSentSinceProgessNotification) / (now - lastTime!)
                let avgSpeed = Double(totalBytesSent - totalBytesSentWhenDfuStarted) / (now - startTime!)
                lastTime = now
                totalBytesSentSinceProgessNotification = totalBytesSent
                
                // Notify progress delegate of overall progress
                DispatchQueue.main.async(execute: {
                    aProgressDelegate?.dfuProgressDidChange(
                        for:   aFirmware.currentPart,
                        outOf: aFirmware.parts,
                        to:    Int(totalProgress),
                        currentSpeedBytesPerSecond: currentSpeed,
                        avgSpeedBytesPerSecond:     avgSpeed)
                })
                progress = totalProgress
            }
            
            // Notify handler of current object progress to start sending next one
            if bytesSent == objectSizeInBytes {
                if aPRNValue == 0 || originalPacketsToSendNow < UInt32(aPRNValue) {
                    aCompletion()
                } else {
                    // The whole object has been sent but the DFU target will
                    // send a PRN notification as expected.
                    // The sendData method will be called again
                    // with packetsLeft = 0 (see line 105)
                    
                    // Do nothing
                }
            }
        }
    }

    func resetCounters() {
        bytesSent = 0
    }
}
