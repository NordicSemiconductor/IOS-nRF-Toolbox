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
    
    /**
    Sends the firmware sizes in format [softdevice size, bootloader size, application size], where each size is a UInt32 number.
    
    - parameter size: sizes of firmware in the current part
    */
    func sendFirmwareSize(_ size:DFUFirmwareSize) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        var data = Data(capacity: 12)
        let sdSize = size.softdevice.littleEndian
        let blSize = size.bootloader.littleEndian
        let appSize = size.application.littleEndian
        let sdArray     = self.convertLittleEndianToByteArray(littleEndian: sdSize)
        let blArray     = self.convertLittleEndianToByteArray(littleEndian: blSize)
        let appArray    = self.convertLittleEndianToByteArray(littleEndian: appSize)
        data.append(sdArray, count:4)
        data.append(blArray, count:4)
        data.append(appArray, count:4)

        logger.v("Writing image sizes (\(size.softdevice)b, \(size.bootloader)b, \(size.application)b) to characteristic \(DFUPacket.UUID.uuidString)...")
        logger.d("peripheral.writeValue(0x\(data.hexString), forCharacteristic: \(DFUPacket.UUID.uuidString), type: WithoutResponse)")
        peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    /**
     +     Converts an UInt32 variable to an array of 4 UInt8 entries
     +
     +     - parameter UInt32: The littleEndian value to convers
     +     */
    fileprivate func convertLittleEndianToByteArray( littleEndian : UInt32) -> [UInt8] {
        var littleEndian = littleEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &littleEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }

    /**
     Sends the application firmware size in format [application size] (UInt32).
     
     - parameter size: sizes of firmware in the current part. Only the application size may ne grater than 0.
     */
    func sendFirmwareSize_v1(_ size:DFUFirmwareSize) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        var data = Data(capacity: 4)
        let appSize = size.application.littleEndian
        let appArray = self.convertLittleEndianToByteArray(littleEndian: appSize)
        data.append(appArray, count:4)
        logger.v("Writing image size (\(size.application)b) to characteristic \(DFUPacket.UUID.uuidString)...")
        logger.d("peripheral.writeValue(0x\(data.hexString), forCharacteristic: \(DFUPacket.UUID.uuidString), type: WithoutResponse)")
        peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    /**
     Sends the whole content of the data object.
     
     - parameter data: the data to be sent
     */
    func sendInitPacket(_ data:Data) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Data may be sent in up-to-20-bytes packets
        var offset = 0
        var bytesToSend = data.count
        
        repeat {
            let packetLength = min(bytesToSend, PacketSize)
            let packet = data.subdata(in: offset..<(offset + packetLength))
            logger.v("Writing to characteristic \(DFUPacket.UUID.uuidString)...")
            logger.d("peripheral.writeValue(0x\(packet.hexString), forCharacteristic: \(DFUPacket.UUID.uuidString), type: WithoutResponse)")
            peripheral.writeValue(packet, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            
            offset += packetLength
            bytesToSend -= packetLength
        } while bytesToSend > 0
    }
    
    /**
     Sends next number of packets from given firmware data and reports a progress.
     This method does not notify progress delegate twice about the same percentage.
     
     - parameter number:           number of packets to be sent before a Packet Receipt Notification is expected.
     Set to 0 to disable Packet Receipt Notification procedure (not recommended)
     - parameter firmware:         the firmware to be sent
     - parameter progressDelegate: an optional progress delegate
     */
    func sendNext(_ number:UInt16, packetsOf firmware:DFUFirmware, andReportProgressTo progressDelegate:DFUProgressDelegate?) {
        // Get the peripheral object
        let peripheral = characteristic.service.peripheral
        
        // Some super complicated computations...
        let bytesTotal = firmware.data.count
        let totalPackets = (bytesTotal + PacketSize - 1) / PacketSize
        let packetsSent  = (bytesSent + PacketSize - 1) / PacketSize
        let packetsLeft = totalPackets - packetsSent
        
        // Calculate how many packets should be sent before EOF or next receipt notification
        var packetsToSendNow = min(Int(number), packetsLeft)
        if number == 0 {
            // When Packet Receipt Notification procedure is disabled, the service will send all data here
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
            let packet = firmware.data.subdata(in: bytesSent..<(bytesSent + packetLength))
            peripheral.writeValue(packet, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            
            bytesSent += packetLength
            packetsToSendNow -= 1
            
            // Calculate current transfer speed in bytes per second
            let now = CFAbsoluteTimeGetCurrent()
            let currentSpeed = Double(packetLength) / (now - lastTime!)
            lastTime = now
            
            // Calculate progress
            let currentProgress = (bytesSent * 100 / bytesTotal) // in percantage (0-100)
            
            // Notify progress listener
            if currentProgress > progress {
                let avgSpeed = Double(bytesSent) / (now - startTime!)
                
                DispatchQueue.main.async(execute: {
                    progressDelegate?.onUploadProgress(
                        firmware.currentPart,
                        totalParts: firmware.parts,
                        progress: currentProgress,
                        currentSpeedBytesPerSecond: currentSpeed,
                        avgSpeedBytesPerSecond: avgSpeed)
                })
                progress = currentProgress
            }
        }
    }
}
