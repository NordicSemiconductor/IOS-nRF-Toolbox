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

struct ZephyrPacket: DFUPacket {
    var url: URL
    var data: Data
    
    var name: String {
        return url.lastPathComponent
    }
}

class ZephyrFileManager: DFUFileManager<ZephyrPacket> {
    private var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    private func tmpDir() throws -> URL {
        return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    override func checkAndMoveFiles() throws -> [ZephyrPacket] {
        let packetDir = try tmpDir().appendingPathComponent("dfu")
        
        return try content(of: try tmpDir())
            .map { (packet) -> ZephyrPacket in
                let newUrl = packetDir.appendingPathComponent(packet.name)
                try fileManager.moveItem(atPath: packet.url.path, toPath: newUrl.path)
                return ZephyrPacket(url: newUrl, data: packet.data)
            }
    }
    
    override func readList() throws -> [ZephyrPacket] {
        let packetDir = try tmpDir().appendingPathComponent("zephyr_dfu")
        return try content(of: packetDir)
    }
    
    func content(of dir: URL) throws -> [ZephyrPacket] {
        return try fileManager
        .contentsOfDirectory(atPath: try tmpDir().path)
        .compactMap { str -> ZephyrPacket? in
            guard let url = URL(string: str), url.pathExtension == "bin" else {
                return nil
            }
            let data = try Data(contentsOf: url)
            
            return ZephyrPacket(url: url, data: data)
        }
    }
}

class ZephyrFileSelector: FileSelectorViewController<Data> {
    weak var router: ZephyrDFURouterType?
    
    init(router: ZephyrDFURouterType? = nil, documentPicker: DocumentPicker<Data>) {
        self.router = router
        super.init(documentPicker: documentPicker)
        filterExtension = "bin"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: Data) {
        router?.goToUpdateScreen(data: document)
    }
    
    override func fileWasSelected(file: File) {
        do {
            let data = try Data(contentsOf: file.url)
            documentWasOpened(document: data)
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
}

