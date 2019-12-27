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

/**
 The type of the BIN or HEX file, or selection of content from the Distribution
 packet (ZIP) file.
 
 Select `.softdeviceBootloaderApplication` to sent all files from the ZIP
 (even it there is let's say only application). This works as a filter.
 If you have SD+BL+App in the ZIP, but want to send only App, you may set the
 type to `.application`.

 - softdevice:           Firmware file will be sent as a new SoftDevice.
 - bootloader:           Firmware file will be sent as a new Bootloader.
 - application:          Firmware file will be sent as a new Application.
 - softdeviceBootloader: Firmware file will be sent as a new SoftDevice + Bootloader.
 - softdeviceBootloaderApplication: All content of the ZIP file will be sent.
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
    @objc public let fileName: String?
    /// The URL to the firmware file.
    @objc public let fileUrl: URL?
    
    /// Information whether the firmware was successfully initialized.
    @objc public var valid: Bool {
        return stream != nil
    }
    
    /// The size of each component of the firmware.
    @objc public var size: DFUFirmwareSize {
        return stream!.size
    }
    
    /// Number of connectinos required to transfer the firmware.
    /// This does not include the connection needed to switch to the DFU mode.
    @objc public var parts: Int {
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
     Creates the DFU Firmware object from a Distribution packet (ZIP).
     Such file must contain a manifest.json file with firmware metadata and at
     least one firmware binaries. Read more about the Distribution packet on
     the DFU documentation.
     
     - parameter urlToZipFile: URL to the Distribution packet (ZIP).
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc convenience public init?(urlToZipFile: URL) {
        self.init(urlToZipFile: urlToZipFile,
                  type: DFUFirmwareType.softdeviceBootloaderApplication)
    }
    
    /**
     Creates the DFU Firmware object from a Distribution packet (ZIP).
     Such file must contain a manifest.json file with firmware metadata and at
     least one firmware binaries. Read more about the Distribution packet on
     the DFU documentation.
     
     - parameter urlToZipFile: URL to the Distribution packet (ZIP).
     - parameter type:         The type of the firmware to use.
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc public init?(urlToZipFile: URL, type: DFUFirmwareType) {
        fileUrl = urlToZipFile
        fileName = urlToZipFile.lastPathComponent
        
        // Quickly check if it's a ZIP file
        let ext = urlToZipFile.pathExtension
        if ext.caseInsensitiveCompare("zip") != .orderedSame {
            NSLog("\(fileName!) is not a ZIP file")
            stream = nil
            super.init()
            return nil
        }
        
        do {
            stream = try DFUStreamZip(urlToZipFile: urlToZipFile, type: type)
        } catch let error as NSError {
            NSLog("Error while creating ZIP stream: \(error.localizedDescription)")
            stream = nil
            super.init()
            return nil
        }
        super.init()
    }
    
    /**
     Creates the DFU Firmware object from a Distribution packet (ZIP).
     Such file must contain a manifest.json file with firmware metadata and at
     least one firmware binaries. Read more about the Distribution packet on
     the DFU documentation.
     
     - parameter zipFile: The Distribution packet (ZIP) data.
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc convenience public init?(zipFile: Data) {
        self.init(zipFile: zipFile, type: DFUFirmwareType.softdeviceBootloaderApplication)
    }
    
    /**
     Creates the DFU Firmware object from a Distribution packet (ZIP).
     Such file must contain a manifest.json file with firmware metadata and at
     least one firmware binaries. Read more about the Distribution packet on
     the DFU documentation.
     
     - parameter zipFile: The Distribution packet (ZIP) data.
     - parameter type:    The type of the firmware to use.
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc public init?(zipFile: Data, type: DFUFirmwareType) {
        fileUrl = nil
        fileName = nil
        
        do {
            stream = try DFUStreamZip(zipFile: zipFile, type: type)
        } catch let error as NSError {
            NSLog("Error while creating ZIP stream: \(error.localizedDescription)")
            stream = nil
            super.init()
            return nil
        }
        super.init()
    }
    
    /**
     Creates the DFU Firmware object from a BIN or HEX file. Setting the DAT
     file with an Init packet is optional, but may be required by the bootloader
     (SDK 7.0.0+).
     
     - parameter urlToBinOrHexFile: URL to a BIN or HEX file with the firmware.
     - parameter urlToDatFile:      An optional URL to a DAT file with the Init packet.
     - parameter type:              The type of the firmware.
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc public init?(urlToBinOrHexFile: URL, urlToDatFile: URL?, type: DFUFirmwareType) {
        fileUrl = urlToBinOrHexFile
        fileName = urlToBinOrHexFile.lastPathComponent
        
        // Quickly check if it's a BIN file
        let ext = urlToBinOrHexFile.pathExtension
        let bin = ext.caseInsensitiveCompare("bin") == .orderedSame
        let hex = ext.caseInsensitiveCompare("hex") == .orderedSame
        guard bin || hex else {
            NSLog("\(fileName!) is not a BIN or HEX file")
            stream = nil
            super.init()
            return nil
        }
        
        if let datUrl = urlToDatFile {
            let datExt = datUrl.pathExtension
            guard datExt.caseInsensitiveCompare("dat") == .orderedSame else {
                NSLog("\(fileName!) is not a DAT file")
                stream = nil
                super.init()
                return nil
            }
        }
        
        if bin {
            stream = DFUStreamBin(urlToBinFile: urlToBinOrHexFile,
                                  urlToDatFile: urlToDatFile, type: type)
        } else {
            guard let s = DFUStreamHex(urlToHexFile: urlToBinOrHexFile,
                                       urlToDatFile: urlToDatFile, type: type) else {
                return nil
            }
            stream = s
        }
        super.init()
    }
    
    /**
     Creates the DFU Firmware object from a BIN data. Setting the DAT
     file with an Init packet is optional, but may be required by the bootloader
     (SDK 7.0.0+).
     
     - parameter binFile: Content of the new firmware as BIN.
     - parameter datFile: An optional DAT file data with the Init packet.
     - parameter type:    The type of the firmware.
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc public init?(binFile: Data, datFile: Data?, type: DFUFirmwareType) {
        fileUrl = nil
        fileName = nil
        
        stream = DFUStreamBin(binFile: binFile, datFile: datFile, type: type)
        super.init()
    }
    
    /**
     Creates the DFU Firmware object from a HEX data. Setting the DAT
     file with an Init packet is optional, but may be required by the bootloader
     (SDK 7.0.0+).
     
     - parameter hexFile: Content of the HEX file containing new firmware.
     - parameter datFile: An optional DAT file data with the Init packet.
     - parameter type:    The type of the firmware.
     
     - returns: The DFU firmware object or `nil` in case of an error.
     */
    @objc public init?(hexFile: Data, datFile: Data?, type: DFUFirmwareType) {
        fileUrl = nil
        fileName = nil
        
        guard let s = DFUStreamHex(hexFile: hexFile, datFile: datFile, type: type) else {
            return nil
        }
        stream = s
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
