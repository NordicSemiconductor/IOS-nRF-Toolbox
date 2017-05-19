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

internal class DFUPacket {
    static fileprivate let UUID = CBUUID(string: "00001532-1212-EFDE-1523-785FEABCD123")
    
    static func matches(_ characteristic: CBCharacteristic) -> Bool {
        return characteristic.uuid.isEqual(UUID)
    }
    
    private let PacketSize: UInt32 = 20
    
    private var characteristic: CBCharacteristic
    private var logger: LoggerHelper
    
    /// Number of bytes of firmware already sent.
    private(set) var bytesSent: UInt32 = 0
    /// Number of bytes sent at the last progress notification. This value is used to calculate the current speed.
    private var bytesSentSinceProgessNotification: UInt32 = 0
    
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
    
    /**
    Sends the firmware sizes in format [softdevice size, bootloader size, application size], where each size is a UInt32 number.
    
    - parameter size: sizes of firmware in the current part
    */
    func sendFirmwareSize(_ size: DFUFirmwareSize) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        var data     = Data(capacity: 12)
        data += size.softdevice.littleEndian
        data += size.bootloader.littleEndian
        data += size.application.littleEndian
        
        logger.v("Writing image sizes (\(size.softdevice)b, \(size.bootloader)b, \(size.application)b) to characteristic \(DFUPacket.UUID.uuidString)...")
        logger.d("peripheral.writeValue(0x\(data.hexString), for: \(DFUPacket.UUID.uuidString), type: .withoutResponse)")
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }

    /**
     Sends the application firmware size in format [application size] (UInt32).
     
     - parameter size: sizes of firmware in the current part. Only the application size may ne grater than 0.
     */
    func sendFirmwareSize_v1(_ size: DFUFirmwareSize) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        var data     = Data(capacity: 4)
        data += size.application.littleEndian
        
        logger.v("Writing image size (\(size.application)b) to characteristic \(DFUPacket.UUID.uuidString)...")
        logger.d("peripheral.writeValue(0x\(data.hexString), for: \(DFUPacket.UUID.uuidString), type: .withoutResponse)")
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    /**
     Sends the whole content of the data object.
     
     - parameter data: the data to be sent
     */
    func sendInitPacket(_ data: Data) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Data may be sent in up-to-20-bytes packets
        var offset: UInt32 = 0
        var bytesToSend = UInt32(data.count)
        
        repeat {
            let packetLength = min(bytesToSend, PacketSize)
            let packet = data.subdata(in: Int(offset) ..< Int(offset + packetLength))
            logger.v("Writing to characteristic \(DFUPacket.UUID.uuidString)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), for: \(DFUPacket.UUID.uuidString), type: .withoutResponse)")
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }
    
    /**
     Sends next number of packets from given firmware data and reports a progress.
     This method does not notify progress delegate twice about the same percentage.
     
     - parameter number:           number of packets to be sent before a Packet Receipt Notification is expected.
     Set to 0 to disable Packet Receipt Notification procedure (not recommended)
     - parameter aFirmware:         the firmware to be sent
     - parameter aProgressDelegate: an optional progress delegate
     */
    func sendNext(_ number: UInt16, packetsOf aFirmware: DFUFirmware, andReportProgressTo aProgressDelegate: DFUProgressDelegate?) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Some super complicated computations...
        let bytesTotal   = UInt32(aFirmware.data.count)
        let totalPackets = (bytesTotal + PacketSize - 1) / PacketSize
        let packetsSent  = (bytesSent + PacketSize - 1) / PacketSize
        let packetsLeft  = totalPackets - packetsSent
        
        // Calculate how many packets should be sent before EOF or next receipt notification
        var packetsToSendNow = min(UInt32(number), packetsLeft)
        if number == 0 {
            // When Packet Receipt Notification procedure is disabled, the service will send all data here
            packetsToSendNow = totalPackets
        }
        
        // Initialize timers
        if startTime == nil {
            startTime = CFAbsoluteTimeGetCurrent()
            lastTime = startTime
            
            // Notify progress delegate that upload has started (0%)
            DispatchQueue.main.async(execute: {
                aProgressDelegate?.dfuProgressDidChange(
                    for:   aFirmware.currentPart,
                    outOf: aFirmware.parts,
                    to:    0,
                    currentSpeedBytesPerSecond: 0.0,
                    avgSpeedBytesPerSecond:     0.0)
            })
        }
        
        while packetsToSendNow > 0 {
            let bytesLeft    = bytesTotal - bytesSent
            let packetLength = min(bytesLeft, PacketSize)
            let packet       = aFirmware.data.subdata(in: Int(bytesSent) ..< Int(bytesSent + packetLength))
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate progress
            let currentProgress = UInt8(bytesSent * 100 / bytesTotal) // in percantage (0-100)
            
            // Notify progress listener
            if currentProgress > progress {
                // Calculate current transfer speed in bytes per second
                let now = CFAbsoluteTimeGetCurrent()
                let currentSpeed = Double(bytesSent - bytesSentSinceProgessNotification) / (now - lastTime!)
                let avgSpeed = Double(bytesSent) / (now - startTime!)
                lastTime = now
                bytesSentSinceProgessNotification = bytesSent
                
                DispatchQueue.main.async(execute: {
                    aProgressDelegate?.dfuProgressDidChange(
                        for:   aFirmware.currentPart,
                        outOf: aFirmware.parts,
                        to:    Int(currentProgress),
                        currentSpeedBytesPerSecond: currentSpeed,
                        avgSpeedBytesPerSecond:     avgSpeed)
                })
                progress = currentProgress
            }
        }
    }
}
