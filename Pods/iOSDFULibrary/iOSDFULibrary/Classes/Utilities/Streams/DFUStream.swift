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

import Foundation

internal let FIRMWARE_TYPE_SOFTDEVICE  : UInt8 = 0x01
internal let FIRMWARE_TYPE_BOOTLOADER  : UInt8 = 0x02
internal let FIRMWARE_TYPE_APPLICATION : UInt8 = 0x04

@objc open class DFUFirmwareSize : NSObject {
    /// Size of the softdevice in bytes.
    /// If not even, add it to the bootloader size to get size of
    /// softdevice_bootloader.bin.
    @objc open fileprivate(set) var softdevice  : UInt32 = 0
    /// Size of the bootloader in bytes. 
    /// If equal to 1 the ZIP contains SD+BL and size of SD or BL is not known exactly,
    /// but their sum is known.
    @objc open fileprivate(set) var bootloader  : UInt32 = 0
    /// Size of the application in bytes.
    @objc open fileprivate(set) var application : UInt32 = 0
    
    internal init(softdevice: UInt32, bootloader: UInt32, application: UInt32) {
        self.softdevice = softdevice
        self.bootloader = bootloader
        self.application = application
    }
}

/**
 * The stream to read firmware from.
 */
internal protocol DFUStream {
    /// Returns the 1-based number of the current part.
    var currentPart: Int { get }
    /// Number of parts to be sent.
    var parts: Int { get }
    /// The size of each component of the firmware.
    var size: DFUFirmwareSize { get }
    /// The size of each component of the firmware from the current part.
    var currentPartSize: DFUFirmwareSize { get }
    /// The type of the current part. See FIRMWARE_TYPE_* constants.
    var currentPartType: UInt8 { get }
    
    /// The firmware data to be sent to the DFU target.
    var data: Data { get }
    /// The whole init packet matching the current part.
    /// Data may be longer than 20 bytes.
    var initPacket: Data? { get }
    
    /**
     Returns `true` if there is another part to be send.
     
     - returns: `True` if there is at least one byte of data not sent in the
                current packet; `false` otherwise.
     */
    func hasNextPart() -> Bool
    /**
     Switches the stream to the second part.
     */
    func switchToNextPart()
}
