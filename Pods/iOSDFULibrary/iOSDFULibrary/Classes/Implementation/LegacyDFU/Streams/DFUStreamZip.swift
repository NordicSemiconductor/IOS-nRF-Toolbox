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

// import EVReflection
import EVReflection

// Errors
internal enum DFUStreamZipError : ErrorType {
    case NoManifest
    case InvalidManifest
    case FileNotFound
    case TypeNotFound
    
    var description:String {
        switch self {
        case .NoManifest: return NSLocalizedString("No manifest file found", comment: "")
        case .InvalidManifest: return NSLocalizedString("Invalid manifest.json file", comment: "")
        case .FileNotFound: return NSLocalizedString("File specified in manifest.json not found in ZIP", comment: "")
        case .TypeNotFound: return NSLocalizedString("Specified type not found in manifest.json", comment: "")
        }
    }
}

// Manifest model
internal class ManifestFirmwareInfo : EVObject {
    var binFile:String? = nil
    var datFile:String? = nil
    
    var valid:Bool {
        return binFile != nil && datFile != nil
    }
    
    override func propertyMapping() -> [(String?, String?)] {
        // Ignore init_packet_data section
        return [("init_packet_data", nil)]
    }
}

internal class SoftdeviceBootloaderInfo : ManifestFirmwareInfo {
    var blSize:UInt32 = 0
    var sdSize:UInt32 = 0
}

internal class Manifest : EVObject {
    var application:ManifestFirmwareInfo?
    var softdevice:ManifestFirmwareInfo?
    var bootloader:ManifestFirmwareInfo?
    var softdeviceBootloader:SoftdeviceBootloaderInfo?
    
    var valid:Bool {
        // The manifest.json file may specify only:
        // 1. a softdevice, a bootloader, or both combined (with, or without an app)
        // 2. only the app
        let hasApplication = application != nil
        var count = 0
        
        count += softdevice != nil ? 1 : 0
        count += bootloader != nil ? 1 : 0
        count += softdeviceBootloader != nil ? 1 : 0
        
        return count == 1 || (count == 0 && hasApplication)
    }
}

internal class ManifestData : EVObject {
    var manifest:Manifest?
}

internal class DFUStreamZip : DFUStream {
    private static let MANIFEST_FILE = "manifest.json"
    
    private(set) var currentPart = 1
    private(set) var parts = 1
    private(set) var currentPartType:UInt8 = 0
    
    /// The parsed manifest file if such found, nil otherwise.
    private var manifestData:ManifestData?
    /// Binaries with softdevice and bootloader.
    private var systemBinaries:NSData?
    /// Binaries with an app.
    private var appBinaries:NSData?
    /// System init packet.
    private var systemInitPacket:NSData?
    /// Application init packet.
    private var appInitPacket:NSData?
    
    private var currentBinaries:NSData?
    private var currentInitPacket:NSData?
    
    private var softdeviceSize:UInt32 = 0
    private var bootloaderSize:UInt32 = 0
    private var applicationSize:UInt32 = 0
    
    var size:DFUFirmwareSize {
        return DFUFirmwareSize(softdevice: softdeviceSize, bootloader: bootloaderSize, application: applicationSize)
    }
    
    var currentPartSize:DFUFirmwareSize {
        // If the ZIP file will be transferred in one part, return all sizes. Two of them will be 0.
        if parts == 1 {
            return DFUFirmwareSize(softdevice: softdeviceSize, bootloader: bootloaderSize, application: applicationSize)
        }
        // Else, return sizes based on the current part number. First the SD and/or BL are uploaded
        if currentPart == 1 {
            return DFUFirmwareSize(softdevice: softdeviceSize, bootloader: bootloaderSize, application: 0)
        }
        // and then the application.
        return DFUFirmwareSize(softdevice: 0, bootloader: 0, application: applicationSize)
    }
    
    /**
     Initializes the stream with URL to the ZIP file.
     
     - parameter urlToZipFile: URL to the ZIP file with firmware files and manifest.json file containing metadata.
     
     - throws: DFUStreamZipError when manifest file was not found or contained an error
     
     - returns: the stream
     */
    convenience init(urlToZipFile:NSURL) throws {
        let allTypes = FIRMWARE_TYPE_SOFTDEVICE | FIRMWARE_TYPE_BOOTLOADER | FIRMWARE_TYPE_APPLICATION
        try self.init(urlToZipFile: urlToZipFile, type: allTypes)
    }
    
    /**
     Initializes the stream with URL to the ZIP file.
     
     - parameter urlToZipFile: URL to the ZIP file with firmware files and manifest.json file containing metadata.
     - parameter type:         The type of the firmware to use
     
     - throws: DFUStreamZipError when manifest file was not found or contained an error
     
     - returns: the stream
     */
    init(urlToZipFile:NSURL, type:UInt8) throws {
        // Try to unzip the file. This may throw an exception
        let contentUrls = try ZipArchive.unzip(urlToZipFile)
        
        // Look for MANIFEST_FILE
        let manifestUrl = ZipArchive.findFile(DFUStreamZip.MANIFEST_FILE, inside: contentUrls)
        
        if let url = manifestUrl {
            // Read manifest content
            let json = try String(contentsOfURL: url)
            
            // EVReflection library is used to deserialize JSON
            // As we use it in a framework, we have to set the bundle identifier manually
            // TODO change this if EVReflection fixed: https://github.com/evermeer/EVReflection/issues/25
            EVReflection.setBundleIdentifier(ManifestData)
            
            // Deserialize json
            manifestData = ManifestData(json: json)
            
            if let manifest = manifestData?.manifest {
                if !manifest.valid {
                    throw DFUStreamZipError.InvalidManifest
                }
                
                // After validation we are sure that the manifest file contains at most one
                // of: softdeviceBootloader, softdevice or bootloader
                
                // Look for and assign files specified in the manifest
                let softdeviceBootloaderType = FIRMWARE_TYPE_SOFTDEVICE | FIRMWARE_TYPE_BOOTLOADER
                if type & softdeviceBootloaderType == softdeviceBootloaderType {
                    if let softdeviceBootloader = manifest.softdeviceBootloader {
                        let (bin, dat) = try getContentOf(softdeviceBootloader, from: contentUrls)
                        systemBinaries = bin
                        systemInitPacket = dat
                        softdeviceSize = softdeviceBootloader.sdSize
                        bootloaderSize = softdeviceBootloader.blSize
                        currentPartType = softdeviceBootloaderType
                    }
                }
                
                let softdeviceType = FIRMWARE_TYPE_SOFTDEVICE
                if type & softdeviceType == softdeviceType {
                    if let softdevice = manifest.softdevice {
                        if systemBinaries != nil {
                            // It is not allowed to put both softdevice and softdeviceBootloader in the manifest
                            throw DFUStreamZipError.InvalidManifest
                        }
                        let (bin, dat) = try getContentOf(softdevice, from: contentUrls)
                        systemBinaries = bin
                        systemInitPacket = dat
                        softdeviceSize = UInt32(bin.length)
                        currentPartType = softdeviceType
                    }
                }
                
                let bootloaderType = FIRMWARE_TYPE_BOOTLOADER
                if type & bootloaderType == bootloaderType {
                    if let bootloader = manifest.bootloader {
                        if systemBinaries != nil {
                            // It is not allowed to put both bootloader and softdeviceBootloader in the manifest
                            throw DFUStreamZipError.InvalidManifest
                        }
                        let (bin, dat) = try getContentOf(bootloader, from: contentUrls)
                        systemBinaries = bin
                        systemInitPacket = dat
                        bootloaderSize = UInt32(bin.length)
                        currentPartType = bootloaderType
                    }
                }
                
                let applicationType = FIRMWARE_TYPE_APPLICATION
                if type & applicationType == applicationType {
                    if let application = manifest.application {
                        let (bin, dat) = try getContentOf(application, from: contentUrls)
                        appBinaries = bin
                        appInitPacket = dat
                        applicationSize = UInt32(bin.length)
                        if currentPartType == 0 {
                            currentPartType = applicationType
                        } else {
                            // Otherwise the app will be sent as part 2
                            
                            // It is not possible to send SD+BL+App in a single connection, due to a fact that
                            // the softdevice_bootloade_application section is not defined for the manifest.json file.
                            // It would be possible to send both bin (systemBinaries and appBinaries), but there are
                            // two dat files with two Init Packets and non of them matches two combined binaries.
                        }
                    }
                }
                
                if systemBinaries == nil && appBinaries == nil {
                    // The specified type is not included in the manifest.
                    throw DFUStreamZipError.TypeNotFound
                }
                else if systemBinaries != nil {
                    currentBinaries = systemBinaries
                    currentInitPacket = systemInitPacket
                } else {
                    currentBinaries = appBinaries
                    currentInitPacket = appInitPacket
                }
                
                // If the ZIP file contains an app and a softdevice or bootloader,
                // the content will be sent in 2 parts.
                if systemBinaries != nil && appBinaries != nil {
                    parts = 2
                }
            } else {
                throw DFUStreamZipError.InvalidManifest
            }
        } else { // no manifest file
            // This library does not support the old, deprecated name-based ZIP files
            // Please, use the nrf-util app to create a new Distribution packet
            throw DFUStreamZipError.NoManifest
        }
    }
    
    /**
     This method checks if the FirmwareInfo object is valid (has both bin and dat files specified),
     adds those files to binUrls and datUrls arrays and returns the length of the bin file in bytes.
     
     - parameter info:        the metadata obtained from the manifest file
     - parameter contentUrls: the list of URLs to the unzipped files
     
     - throws: DFUStreamZipError when file specified in the metadata was not found in the ZIP
     
     - returns: content bin and dat files
     */
    private func getContentOf(info:ManifestFirmwareInfo, from contentUrls:[NSURL]) throws -> (NSData, NSData?) {
        if !info.valid {
            throw DFUStreamZipError.InvalidManifest
        }
        
        // Get the URLs to the bin and dat files specified in the FirmwareInfo
        let bin = ZipArchive.findFile(info.binFile!, inside: contentUrls)
        var dat:NSURL? = nil
        if let datFile = info.datFile {
            dat = ZipArchive.findFile(datFile, inside: contentUrls)
        }
        
        // Check if the files were found in the ZIP
        if bin == nil || (info.datFile != nil && dat == nil) {
            throw DFUStreamZipError.FileNotFound
        }
        
        // Read content of those files
        let binData = NSData(contentsOfURL: bin!)!
        var datData:NSData? = nil
        if let dat = dat {
            datData = NSData(contentsOfURL: dat)!
        }
        
        return (binData, datData)
    }
    
    var data:NSData {
        return currentBinaries!
    }
    
    var initPacket:NSData? {
        return currentInitPacket
    }
    
    func hasNextPart() -> Bool {
        return currentPart < parts
    }
    
    func switchToNextPart() {
        if currentPart == 1 && parts == 2 {
            currentPart = 2
            currentPartType = FIRMWARE_TYPE_APPLICATION
            currentBinaries = appBinaries
            currentInitPacket = appInitPacket
        }
    }
}
