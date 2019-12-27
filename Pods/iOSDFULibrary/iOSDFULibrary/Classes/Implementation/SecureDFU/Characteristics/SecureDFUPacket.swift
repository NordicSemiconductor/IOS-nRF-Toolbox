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

import CoreBluetooth

internal class SecureDFUPacket: DFUCharacteristic {
    
    private let packetSize: UInt32
    
    internal var characteristic: CBCharacteristic
    internal var logger: LoggerHelper

    /// Number of bytes of firmware already sent.
    private(set) var bytesSent: UInt32 = 0
    /// Number of bytes sent at the last progress notification.
    /// This value is used to calculate the current speed.
    private var totalBytesSentSinceProgessNotification: UInt32 = 0
    private var totalBytesSentWhenDfuStarted: UInt32 = 0

    /// Current progress in percents (0-99).
    private var progressReported: UInt8 = 0
    private var startTime: CFAbsoluteTime?
    private var lastTime:  CFAbsoluteTime?

    internal var valid: Bool {
        return characteristic.properties.contains(.writeWithoutResponse)
    }
    
    required init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
        
        if #available(iOS 9.0, macOS 10.12, *) {
            packetSize = UInt32(characteristic.service.peripheral.maximumWriteValueLength(for: .withoutResponse))
            if packetSize > 20 {
                // MTU is 3 bytes larger than payload
                // (1 octet for Op-Code and 2 octets for Att Handle).
                logger.v("MTU set to \(packetSize + 3)")
            }
        } else {
            packetSize = 20 // Default MTU is 23.
        }
    }
    
    // MARK: - Characteristic API methods
    
    /**
     Sends the whole content of the data object.
     
     - parameter data: The data to be sent.
     */
    func sendInitPacket(_ data: Data) {
        // Get the peripheral object.
        let peripheral = characteristic.service.peripheral
        
        // Data may be sent in up-to-20-bytes packets.
        var offset: UInt32 = 0
        var bytesToSend = UInt32(data.count)
        
        let packetUUID = characteristic.uuid.uuidString
        repeat {
            let packetLength = min(bytesToSend, packetSize)
            let packet = data.subdata(in: Int(offset) ..< Int(offset + packetLength))
            
            logger.v("Writing to characteristic \(packetUUID)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), for: \(packetUUID), type: .withoutResponse)")
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }

    /**
     Sends a given range of data from given firmware over DFU Packet characteristic.
     If the whole object is completed the completition callback will be called.
     
     - parameters:
       - prnValue: Packet Receipt Notification value used in the process. 0 to disable PRNs.
       - range:    The range of the firmware that is to be sent in this object.
       - firmware: The whole firmware to be sent in this part.
       - progress: An optional progress delegate.
       - queue:    The queue to dispatch progress events on.
       - complete: The completon callback.
     */
    func sendNext(_ prnValue: UInt16, packetsFrom range: Range<Int>, of firmware: DFUFirmware,
                  andReportProgressTo progress: DFUProgressDelegate?, on queue: DispatchQueue,
                  andCompletionTo complete: @escaping Callback) {
        let peripheral          = characteristic.service.peripheral
        let objectData          = firmware.data.subdata(in: range)
        let objectSizeInBytes   = UInt32(objectData.count)
        let objectSizeInPackets = (objectSizeInBytes + packetSize - 1) / packetSize
        let packetsSent         = (bytesSent + packetSize - 1) / packetSize
        let packetsLeft         = objectSizeInPackets - packetsSent

        // Calculate how many packets should be sent before EOF or next receipt notification.
        var packetsToSendNow = min(UInt32(prnValue), packetsLeft)
        
        if prnValue == 0 {
            packetsToSendNow = packetsLeft
        }
        
        // This is called when we no longer have data to send (PRN received after the whole
        // object was sent). Fixes issue IDFU-9.
        if packetsToSendNow == 0 {
            complete()
            return
        }

        // Initialize timers.
        if startTime == nil {
            startTime = CFAbsoluteTimeGetCurrent()
            lastTime = startTime
            totalBytesSentWhenDfuStarted = UInt32(range.lowerBound)
            totalBytesSentSinceProgessNotification = totalBytesSentWhenDfuStarted
            
            // Notify progress delegate that upload has started (0%).
            queue.async(execute: {
                progress?.dfuProgressDidChange(
                    for:   firmware.currentPart,
                    outOf: firmware.parts,
                    to:    0,
                    currentSpeedBytesPerSecond: 0.0,
                    avgSpeedBytesPerSecond:     0.0)
            })
        }
        
        let originalPacketsToSendNow = packetsToSendNow
        while packetsToSendNow > 0 {
            // Starting from iOS 11 and MacOS 10.13 the PRNs are no longer required due to new API.
            var canSendPacket = true
            if #available(iOS 11.0, macOS 10.13, *) {
                // The peripheral.canSendWriteWithoutResponse often returns false before even we
                // start sending, let's do a workaround.
                canSendPacket = bytesSent == 0 || peripheral.canSendWriteWithoutResponse
            }
            // If PRNs are enabled we will ignore the new API and base synchronization on PRNs only.
            guard canSendPacket || prnValue > 0 else {
                break
            }
            
            let bytesLeft = objectSizeInBytes - bytesSent
            let packetLength = min(bytesLeft, packetSize)
            let packet = objectData.subdata(in: Int(bytesSent) ..< Int(packetLength + bytesSent))
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate the total progress of the firmware, presented to the delegate.
            let totalBytesSent = UInt32(range.lowerBound) + bytesSent
            let currentProgress = UInt8(totalBytesSent * 100 / UInt32(firmware.data.count)) // in percantage (0-100)
            
            // Notify progress listener only if current progress has increased since last time.
            if currentProgress > progressReported {
                // Calculate current transfer speed in bytes per second.
                let now = CFAbsoluteTimeGetCurrent()
                let currentSpeed = Double(totalBytesSent - totalBytesSentSinceProgessNotification) / (now - lastTime!)
                let avgSpeed = Double(totalBytesSent - totalBytesSentWhenDfuStarted) / (now - startTime!)
                lastTime = now
                totalBytesSentSinceProgessNotification = totalBytesSent
                
                // Notify progress delegate of overall progress.
                queue.async(execute: {
                    progress?.dfuProgressDidChange(
                        for:   firmware.currentPart,
                        outOf: firmware.parts,
                        to:    Int(currentProgress),
                        currentSpeedBytesPerSecond: currentSpeed,
                        avgSpeedBytesPerSecond:     avgSpeed)
                })
                progressReported = currentProgress
            }
            
            // Notify handler of current object progress to start sending next one.
            if bytesSent == objectSizeInBytes {
                if prnValue == 0 || originalPacketsToSendNow < UInt32(prnValue) {
                    complete()
                } else {
                    // The whole object has been sent but the DFU target will
                    // send a PRN notification as expected.
                    // The sendData method will be called again
                    // with packetsLeft = 0 (see line 132).
                    
                    // Do nothing.
                }
            }
        }
    }

    func resetCounters() {
        bytesSent = 0
    }
}
