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



import UIKit.UIDocumentPickerViewController
import UniformTypeIdentifiers
import ZIPFoundation

private struct JSONManifest: Codable {
    struct FirmwareFile: Codable {
        let file: String
        let imageIndex: Int
        
        enum CodingKeys: String, CodingKey {
            case file
            case imageIndex = "image_index"
        }
    }
    
    let files: [FirmwareFile]
}


private enum FileType {
    case bin, zip, unknown
    
    init(url: URL) {
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
            // Fallback on earlier versions
        }
        } catch {
            self = .unknown
        }
    }
}

class ZephyrDFUDocumentPicker: DocumentPicker<McuMgrFirmware> {
    enum Error: Swift.Error {
        case unknownFileType, badArchive
        
        var localizedDescription: String {
            switch self {
            case .unknownFileType: return "Unsupported file format"
            case .badArchive: return "Archive doesn't contain required files"
            }
        }
    }
    
    init() {
        super.init(documentTypes: ["public.data", "public.zip"])
    }
    
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        do {
            switch FileType(url: url) {
            case .bin:
                callback(.success(McuMgrFirmware(data: try Data(contentsOf: url))))
            case .zip:
                callback(.success(try extract(file: url)))
            case .unknown:
                callback(.failure(Error.unknownFileType))
            }
        } catch let error {
            callback(.failure(error))
        }
    }
    
    private func extract(file: URL) throws -> McuMgrFirmware {
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
