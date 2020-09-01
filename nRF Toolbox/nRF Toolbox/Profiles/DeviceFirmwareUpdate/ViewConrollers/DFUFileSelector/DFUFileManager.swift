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


import Core
import Foundation
import iOSDFULibrary

protocol DFUPacket {
    var url: URL { get }
    var name: String { get }
}

struct DFUDistributionPacket: DFUPacket {
    let url: URL
    var name: String {
        url.lastPathComponent
    }
    var firmware: DFUFirmware? = nil
}

class DFUFileManager<T: DFUPacket> {
    
    func readList() throws -> [T] {
        fatalError("\(#function): override me!")
    }
    
    func handleUrl(_ url: URL) -> Bool {
        return false
    }
    
    func checkAndMoveFiles() throws -> [T] {
        fatalError("\(#function): override me!")
    }
}

class DFUPacketManager: DFUFileManager<DFUDistributionPacket> {
    private var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    private func documentDir() throws -> URL {
        return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    private func inboxDir() throws -> URL {
        return try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    private func dfuDir() throws -> URL {
        let dfuDir = try documentDir().appendingPathComponent("dfu")
        var isDir : ObjCBool = false
        if !fileManager.fileExists(atPath: dfuDir.path, isDirectory: &isDir) {
            try fileManager.createDirectory(atPath: dfuDir.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return dfuDir
    }
    
    override func handleUrl(_ url: URL) -> Bool {
        guard url.isFileURL,
            url.pathExtension == "zip",
            let newUrl = try? dfuDir().appendingPathComponent(url.lastPathComponent) else {
                return false
        }
        
        do {
            try fileManager.moveItem(at: url, to: newUrl)
        } catch let error {
            SystemLog(category: .util, type: .error).log(message: error.localizedDescription)
            return false
        }
        
        return true
    }
    
    override func readList() throws -> [DFUDistributionPacket] {
        return try content(of: try dfuDir())
    }
    
    func content(of dir: URL) throws -> [DFUDistributionPacket] {
        return try fileManager
            .contentsOfDirectory(atPath: dir.path)
        .compactMap { str -> DFUDistributionPacket? in
            let fileUrl = dir.appendingPathComponent(str)
            guard let firmware = DFUFirmware(urlToZipFile: fileUrl) else {
                return nil
            }
            return DFUDistributionPacket(url: fileUrl, firmware: firmware)
        }
    }
    
}
