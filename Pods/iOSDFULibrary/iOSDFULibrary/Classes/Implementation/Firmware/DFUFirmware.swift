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

/**
The type of the BIN or HEX file.

- Softdevice:           Firmware file will be sent as a new Softdevice
- Bootloader:           Firmware file will be sent as a new Bootloader
- Application:          Firmware file will be sent as a new application
*/
@objc public enum DFUFirmwareType : UInt8 {
    case softdevice = 1
    case bootloader = 2
    case application = 4
    // Merged option values (due to objc - Swift compatibility).
    case softdeviceBootloader = 3
    case softdeviceBootloaderApplication = 7
}

/// The DFUFirmware object wraps the firmware file.
@objc public class DFUFirmware : NSObject, DFUStream {
    internal let stream: DFUStream?
    
    /// The name of the firmware file.
    public let fileName: String!
    /// The URL to the firmware file.
    public let fileUrl: URL!
    
    /// Information whether the firmware was successfully initialized.
    public var valid: Bool {
        return stream != nil
    }
    
    /// The size of each component of the firmware.
    public var size: DFUFirmwareSize {
        return stream!.size
    }
    
    /// Number of connectinos required to transfer the firmware. This does not include the connection needed to switch to the DFU mode.
    public var parts: Int {
        if stream == nil {
            return 0
        }
        return stream!.parts
    }
    
    internal var currentPartSize: DFUFirmwareSize {
        return stream!.currentPartSize
    }
    
    internal var currentPartType: UInt8 {
        return stream!.currentPartType
    }
    
    internal var currentPart: Int {
        return stream!.currentPart
    }
    
    /**
     Creates the DFU Firmware object from a Distribution packet (ZIP). Such file must contain a manifest.json file
     with firmware metadata and at least one firmware binaries. Read more about the Distribution packet on
     the DFU documentation.
     
     - parameter urlToZipFile: URL to the Distribution packet (ZIP)
     
     - returns: the DFU firmware object or null in case of an error
     */
    convenience public init?(urlToZipFile: URL) {
        self.init(urlToZipFile: urlToZipFile, type: DFUFirmwareType.softdeviceBootloaderApplication)
    }
    
    /**
     Creates the DFU Firmware object from a Distribution packet (ZIP). Such file must contain a manifest.json file
     with firmware metadata and at least one firmware binaries. Read more about the Distribution packet on
     the DFU documentation.
     
     - parameter urlToZipFile: URL to the Distribution packet (ZIP)
     - parameter type:         the type of the firmware to use
     
     - returns: the DFU firmware object or null in case of an error
     */
    public init?(urlToZipFile: URL, type: DFUFirmwareType) {
        fileUrl = urlToZipFile
        fileName = urlToZipFile.lastPathComponent
        
        // Quickly check if it's a ZIP file
        let ext = urlToZipFile.pathExtension
        if ext.caseInsensitiveCompare("zip") != .orderedSame {
            NSLog("\(self.fileName) is not a ZIP file")
            stream = nil
            super.init()
            return nil
        }
        
        do {
            stream = try DFUStreamZip(urlToZipFile: urlToZipFile, type: type.rawValue)
        } catch let error as NSError {
            NSLog("Error while creating ZIP stream: \(error.localizedDescription)")
            stream = nil
            super.init()
            return nil
        }
        super.init()
    }
    
    /**
     Creates the DFU Firmware object from a BIN or HEX file. Setting the DAT file with an Init packet is optional,
     but may be required by the bootloader.
     
     - parameter urlToBinOrHexFile: URL to a BIN or HEX file with the firmware
     - parameter urlToDatFile: optional URL to a DAT file with the Init packet
     - parameter type:         The type of the firmware
     
     - returns: the DFU firmware object or null in case of an error
     */
    public init?(urlToBinOrHexFile: URL, urlToDatFile: URL?, type: DFUFirmwareType) {
        self.fileUrl = urlToBinOrHexFile
        self.fileName = urlToBinOrHexFile.lastPathComponent
        
        // Quickly check if it's a BIN file
        let ext = urlToBinOrHexFile.pathExtension
        let bin = ext.caseInsensitiveCompare("bin") == .orderedSame
        let hex = ext.caseInsensitiveCompare("hex") == .orderedSame
        if !bin && !hex {
            NSLog("\(self.fileName) is not a BIN or HEX file")
            stream = nil
            super.init()
            return nil
        }
        
        if let datUrl = urlToDatFile {
            let datExt = datUrl.pathExtension
            if datExt.caseInsensitiveCompare("dat") != .orderedSame {
                NSLog("\(self.fileName) is not a DAT file")
                stream = nil
                super.init()
                return nil
            }
        }
        
        if bin {
            stream = DFUStreamBin(urlToBinFile: urlToBinOrHexFile, urlToDatFile: urlToDatFile, type: type)
        } else {
            stream = DFUStreamHex(urlToHexFile: urlToBinOrHexFile, urlToDatFile: urlToDatFile, type: type)
        }
        super.init()
    }
    
    internal var data: Data {
        return stream!.data as Data
    }
    
    internal var initPacket: Data? {
        return stream!.initPacket as Data?
    }
    
    internal func hasNextPart() -> Bool {
        return stream!.hasNextPart()
    }
    
    internal func switchToNextPart() {
        stream!.switchToNextPart()
    }
}
