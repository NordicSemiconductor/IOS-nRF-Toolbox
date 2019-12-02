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

internal class DFUPacket: DFUCharacteristic {

    private let packetSize: UInt32 = 20 // Legacy DFU does not support higher MTUs.
    
    internal var characteristic: CBCharacteristic
    internal var logger: LoggerHelper

    /// Number of bytes of firmware already sent.
    private(set) var bytesSent: UInt32 = 0
    /// Number of bytes sent at the last progress notification. This value is used
    /// to calculate the current speed.
    private var bytesSentSinceProgessNotification: UInt32 = 0
    
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
    }
    
    // MARK: - Characteristic API methods
    
    /**
     Sends the firmware sizes in format [softdevice size, bootloader size, application size],
     where each size is a UInt32 number.
    
     - parameter size: Sizes of firmware in the current part.
     */
    func sendFirmwareSize(_ size: DFUFirmwareSize) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        var data = Data(capacity: 12)
        data += size.softdevice.littleEndian
        data += size.bootloader.littleEndian
        data += size.application.littleEndian

        let packetUUID = characteristic.uuid.uuidString
        
        logger.v("Writing image sizes (\(size.softdevice)b, \(size.bootloader)b, \(size.application)b) to characteristic \(packetUUID)...")
        logger.d("peripheral.writeValue(0x\(data.hexString), for: \(packetUUID), type: .withoutResponse)")
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }

    /**
     Sends the application firmware size in format [application size] (UInt32).
     
     - parameter size: Sizes of firmware in the current part.
                       Only the application size may be grater than 0.
     */
    func sendFirmwareSize_v1(_ size: DFUFirmwareSize) {
        // Get the peripheral object.
        let peripheral = characteristic.service.peripheral
        
        var data = Data(capacity: 4)
        data += size.application.littleEndian

        let packetUUID = characteristic.uuid.uuidString

        logger.v("Writing image size (\(size.application)b) to characteristic \(packetUUID)...")
        logger.d("peripheral.writeValue(0x\(data.hexString), for: \(packetUUID), type: .withoutResponse)")
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
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
        
        repeat {
            let packetLength = min(bytesToSend, packetSize)
            let packet = data.subdata(in: Int(offset) ..< Int(offset + packetLength))

            let packetUUID = characteristic.uuid.uuidString

            logger.v("Writing to characteristic \(packetUUID)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), for: \(packetUUID), type: .withoutResponse)")

            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }
    
    /**
     Sends next number of packets from given firmware data and reports a progress.
     This method does not notify progress delegate twice about the same percentage.
     
     - parameter prnValue: Number of packets to be sent before a Packet Receipt
                           Notification is expected. Set to 0 to disable Packet
                           Receipt Notification procedure.
     - parameter firmware: The firmware to be sent.
     - parameter progress: An optional progress delegate.
     - parameter queue:    The queue to dispatch progress events on.
     */
    func sendNext(_ prnValue: UInt16, packetsOf firmware: DFUFirmware,
                  andReportProgressTo progress: DFUProgressDelegate?, on queue: DispatchQueue) {
        // Get the peripheral object.
        let peripheral = characteristic.service.peripheral
        
        // Some super complicated computations...
        let bytesTotal   = UInt32(firmware.data.count)
        let totalPackets = (bytesTotal + packetSize - 1) / packetSize
        let packetsSent  = (bytesSent + packetSize - 1) / packetSize
        let packetsLeft  = totalPackets - packetsSent
        
        // Calculate how many packets should be sent before EOF or next receipt
        // notification.
        var packetsToSendNow = min(UInt32(prnValue), packetsLeft)
        if prnValue == 0 {
            // When Packet Receipt Notification procedure is disabled, the service
            // will send all data here.
            packetsToSendNow = packetsLeft
        }
        
        // Initialize timers.
        if startTime == nil {
            startTime = CFAbsoluteTimeGetCurrent()
            lastTime = startTime
            
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
        
        while packetsToSendNow > 0 {
            // Starting from iOS 11 and MacOS 10.13 the PRNs are no longer required
            // due to new API.
            var canSendPacket = true
            if #available(iOS 11.0, macOS 10.13, *) {
                // The peripheral.canSendWriteWithoutResponse often returns false
                // before even we start sending, let's do a workaround.
                canSendPacket = bytesSent == 0 || peripheral.canSendWriteWithoutResponse
            }
            // If PRNs are enabled we will ignore the new API and base synchronization
            // on PRNs only.
            guard canSendPacket || prnValue > 0 else {
                break
            }
            
            let bytesLeft    = bytesTotal - bytesSent
            let packetLength = min(bytesLeft, packetSize)
            let packet       = firmware.data.subdata(in: Int(bytesSent) ..< Int(bytesSent + packetLength))
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate progress
            let currentProgress = UInt8(bytesSent * 100 / bytesTotal) // in percantage (0-100)
            
            // Notify progress listener.
            if currentProgress > progressReported {
                // Calculate current transfer speed in bytes per second.
                let now = CFAbsoluteTimeGetCurrent()
                let currentSpeed = Double(bytesSent - bytesSentSinceProgessNotification) / (now - lastTime!)
                let avgSpeed = Double(bytesSent) / (now - startTime!)
                lastTime = now
                bytesSentSinceProgessNotification = bytesSent
                
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
        }
    }
}
