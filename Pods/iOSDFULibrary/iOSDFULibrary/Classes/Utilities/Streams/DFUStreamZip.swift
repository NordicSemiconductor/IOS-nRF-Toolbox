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

// Errors
internal enum DFUStreamZipError : Error {
    case noManifest
    case invalidManifest
    case fileNotFound
    case typeNotFound
    
    var description: String {
        switch self {
        case .noManifest:      return NSLocalizedString("No manifest file found", comment: "")
        case .invalidManifest: return NSLocalizedString("Invalid manifest.json file", comment: "")
        case .fileNotFound:    return NSLocalizedString("File specified in manifest.json not found in ZIP", comment: "")
        case .typeNotFound:    return NSLocalizedString("Specified type not found in manifest.json", comment: "")
        }
    }
}

internal class DFUStreamZip : DFUStream {
    private static let MANIFEST_FILE = "manifest.json"
    
    private(set) var currentPart = 1
    private(set) var parts       = 1
    private(set) var currentPartType: UInt8 = 0
    
    /// The parsed manifest file if such found, nil otherwise.
    private var manifest: Manifest?
    /// Binaries with softdevice and bootloader.
    private var systemBinaries: Data?
    /// Binaries with an app.
    private var appBinaries: Data?
    /// System init packet.
    private var systemInitPacket: Data?
    /// Application init packet.
    private var appInitPacket: Data?
    
    private var currentBinaries: Data?
    private var currentInitPacket: Data?
    
    private var softdeviceSize  : UInt32 = 0
    private var bootloaderSize  : UInt32 = 0
    private var applicationSize : UInt32 = 0
    
    var size: DFUFirmwareSize {
        return DFUFirmwareSize(softdevice: softdeviceSize, bootloader: bootloaderSize, application: applicationSize)
    }
    
    var currentPartSize: DFUFirmwareSize {
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
    convenience init(urlToZipFile: URL) throws {
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
    init(urlToZipFile: URL, type: UInt8) throws {
        // Try to unzip the file. This may throw an exception
        let contentUrls = try ZipArchive.unzip(urlToZipFile)
        
        // Look for MANIFEST_FILE
        let manifestUrl = ZipArchive.findFile(DFUStreamZip.MANIFEST_FILE, inside: contentUrls)
        
        if let url = manifestUrl {
            // Read manifest content
            let json = try String(contentsOf: url)
            
            // Deserialize json
            manifest = Manifest(withJsonString: json)

            if manifest!.valid {

                // After validation we are sure that the manifest file contains at most one
                // of: softdeviceBootloader, softdevice or bootloader
                
                // Look for and assign files specified in the manifest
                let softdeviceBootloaderType = FIRMWARE_TYPE_SOFTDEVICE | FIRMWARE_TYPE_BOOTLOADER
                if type & softdeviceBootloaderType == softdeviceBootloaderType {
                    if let softdeviceBootloader = manifest!.softdeviceBootloader {
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
                    if let softdevice = manifest!.softdevice {
                        if systemBinaries != nil {
                            // It is not allowed to put both softdevice and softdeviceBootloader in the manifest
                            throw DFUStreamZipError.invalidManifest
                        }
                        let (bin, dat) = try getContentOf(softdevice, from: contentUrls)
                        systemBinaries = bin
                        systemInitPacket = dat
                        softdeviceSize = UInt32(bin.count)
                        currentPartType = softdeviceType
                    }
                }
                
                let bootloaderType = FIRMWARE_TYPE_BOOTLOADER
                if type & bootloaderType == bootloaderType {
                    if let bootloader = manifest!.bootloader {
                        if systemBinaries != nil {
                            // It is not allowed to put both bootloader and softdeviceBootloader in the manifest
                            throw DFUStreamZipError.invalidManifest
                        }
                        let (bin, dat) = try getContentOf(bootloader, from: contentUrls)
                        systemBinaries = bin
                        systemInitPacket = dat
                        bootloaderSize = UInt32(bin.count)
                        currentPartType = bootloaderType
                    }
                }
                
                let applicationType = FIRMWARE_TYPE_APPLICATION
                if type & applicationType == applicationType {
                    if let application = manifest!.application {
                        let (bin, dat) = try getContentOf(application, from: contentUrls)
                        appBinaries = bin
                        appInitPacket = dat
                        applicationSize = UInt32(bin.count)
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
                    throw DFUStreamZipError.typeNotFound
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
                throw DFUStreamZipError.invalidManifest
            }
        } else { // no manifest file
            // This library does not support the old, deprecated name-based ZIP files
            // Please, use the nrf-util app to create a new Distribution packet
            throw DFUStreamZipError.noManifest
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
    fileprivate func getContentOf(_ info: ManifestFirmwareInfo, from contentUrls: [URL]) throws -> (Data, Data?) {
        if !info.valid {
            throw DFUStreamZipError.invalidManifest
        }
        
        // Get the URLs to the bin and dat files specified in the FirmwareInfo
        let bin = ZipArchive.findFile(info.binFile!, inside: contentUrls)
        var dat: URL? = nil
        if let datFile = info.datFile {
            dat = ZipArchive.findFile(datFile, inside: contentUrls)
        }
        
        // Check if the files were found in the ZIP
        if bin == nil || (info.datFile != nil && dat == nil) {
            throw DFUStreamZipError.fileNotFound
        }
        
        // Read content of those files
        let binData = try! Data(contentsOf: bin!)
        var datData: Data? = nil
        if let dat = dat {
            datData = try! Data(contentsOf: dat)
        }
        
        return (binData, datData)
    }
    
    var data: Data {
        return currentBinaries!
    }
    
    var initPacket: Data? {
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
