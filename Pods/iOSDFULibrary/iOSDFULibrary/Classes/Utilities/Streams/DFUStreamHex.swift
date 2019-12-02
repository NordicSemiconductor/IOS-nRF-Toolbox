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

internal class DFUStreamHex : DFUStream {
    private(set) var currentPart = 1
    private(set) var parts       = 1
    private(set) var currentPartType: UInt8 = 0
    
    /// Firmware binaries.
    private var binaries: Data
    /// The init packet content.
    private var initPacketBinaries: Data?
    
    private var firmwareSize: UInt32 = 0
    
    var size: DFUFirmwareSize {
        switch currentPartType {
        case FIRMWARE_TYPE_SOFTDEVICE:
            return DFUFirmwareSize(softdevice: firmwareSize, bootloader: 0, application: 0)
        case FIRMWARE_TYPE_BOOTLOADER:
            return DFUFirmwareSize(softdevice: 0, bootloader: firmwareSize, application: 0)
     // case FIRMWARE_TYPE_APPLICATION:
        default:
            return DFUFirmwareSize(softdevice: 0, bootloader: 0, application: firmwareSize)
        }
    }
    
    var currentPartSize: DFUFirmwareSize {
        return size
    }
    
    init?(urlToHexFile: URL, urlToDatFile: URL?, type: DFUFirmwareType) {
        let hexData = try! Data(contentsOf: urlToHexFile)
        guard let bin = IntelHex2BinConverter.convert(hexData, mbrSize: 0x1000) else {
            return nil
        }
        binaries = bin
        firmwareSize = UInt32(binaries.count)
        
        if let dat = urlToDatFile {
            initPacketBinaries = try? Data(contentsOf: dat)
        }
        
        currentPartType = type.rawValue
    }
    
    init?(hexFile: Data, datFile: Data?, type: DFUFirmwareType) {
        guard let bin = IntelHex2BinConverter.convert(hexFile, mbrSize: 0x1000) else {
            return nil
        }
        binaries = bin
        firmwareSize = UInt32(binaries.count)
        
        initPacketBinaries = datFile
        
        currentPartType = type.rawValue
    }
    
    var data: Data {
        return binaries
    }
    
    var initPacket: Data? {
        return initPacketBinaries
    }
    
    func hasNextPart() -> Bool {
        return false
    }
    
    func switchToNextPart() {
        // Do nothing.
    }
}
