/*
* Copyright (c) 2020, Nordic Semiconductor
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



import UIKit
import ZIPFoundation

private struct JSONManifest: Codable {
    struct FirmwareFile: Codable {
        let file: String
        let imageIndex: Int
        
        enum CodingKeys: String, CodingKey {
            case file
            case imageIndex = "image_index"
        }
        
        struct BadIndex: Swift.Error {
            var localizedDescription: String {
                "Can't parse image index"
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.file = try container.decode(String.self, forKey: .file)
            self.imageIndex = Int(try container.decode(String.self, forKey: .imageIndex)) ?? -1
            
            if self.imageIndex < 0 {
                throw BadIndex()
            }
        }
    }
    
    let files: [FirmwareFile]
}

private enum FileType {
    case bin, zip, unknown
    
    init(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            self = .unknown
            return
        }
        do {
        if #available(iOS 14.0, *) {
            let typeId = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
            self = typeId == .zip
                ? .zip
                : typeId == .data
                    ? .bin
                    : .unknown
        } else {
            // public.zip-archive
            let typeId = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
            self = typeId == "public.zip-archive"
                ? .zip
                : typeId == "public.data"
                    ? .bin
                    : .unknown
        }
        } catch let e {
            print(e.localizedDescription)
            self = .unknown
        }
    }
}

class ZephyrFileManager {
    enum Error: Swift.Error {
        case unknownFileType, badArchive
        
        var localizedDescription: String {
            switch self {
            case .unknownFileType: return "Unsupported file format"
            case .badArchive: return "Archive doesn't contain required files"
            }
        }
    }
    
    let fileManager: FileManager
    
    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    func createFirmware(from file: URL) throws -> McuMgrFirmware {
        switch FileType(url: file) {
        case .bin:
            return McuMgrFirmware(data: try Data(contentsOf: file))
        case .zip:
            return try extract(file: file)
        case .unknown:
            throw Error.unknownFileType
        }
    }
    
    func extract(file: URL) throws -> McuMgrFirmware {
        let fileManager = FileManager()
        let destinationDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: file, to: destinationDir)
            let manifestData = try Data(contentsOf: destinationDir.appendingPathComponent("manifest.json"))
            let manifest = try JSONDecoder().decode(JSONManifest.self, from: manifestData)
            let images = try manifest.files
                .map { ($0.imageIndex, destinationDir.appendingPathComponent($0.file)) }
                .map { ($0.0, try Data(contentsOf: $0.1)) }
                .reduce(into: [Int: Data]()) { $0[$1.0] = $1.1 }
            return McuMgrFirmware(images: images)
        } catch {
            throw Error.badArchive
        }
    }
}

class ZephyrFileSelector: FileSelectorViewController<McuMgrFirmware> {
    weak var router: ZephyrDFURouterType?
    let fileHandler: ZephyrFileManager
    
    init(router: ZephyrDFURouterType? = nil, fileHandler: ZephyrFileManager = ZephyrFileManager(), documentPicker: DocumentPicker<McuMgrFirmware>) {
        self.router = router
        self.fileHandler = fileHandler
        super.init(documentPicker: documentPicker)
        filterExtension = "bin"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: McuMgrFirmware) {
        router?.goToUpdateScreen(firmware: document)
    }
    
    override func fileWasSelected(file: File) {
        do {
            documentWasOpened(document: try fileHandler.createFirmware(from: file.url))
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
}

