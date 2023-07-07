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



import Foundation

class DocumentFileManager: FileManager {
    func buildDocumentDir() throws -> Directory {
        let docDir = try url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return try buildDir(url: docDir)
    }
    
    func buildDir(url: URL) throws -> Directory {
        let nodes = try buildTree(url: url)
        return Directory(url: url, nodes: nodes)
    }
    
    func buildTree(url: URL) throws -> [FSNode] {
        do {
            return try contentsOfDirectory(atPath: url.path).compactMap { itemName -> FSNode? in
                let itemUrl = url.appendingPathComponent(itemName)
                
                var isDir: ObjCBool = false
                let fileExist = self.fileExists(atPath: itemUrl.path, isDirectory: &isDir)
                
                guard fileExist else { return nil }
                
                let attr = try attributesOfItem(atPath: itemUrl.path)
                let modificationDate = attr[.modificationDate] as? Date
                
                if isDir.boolValue {
                    let nestedNodes = try self.buildTree(url: itemUrl)
                    return Directory(url: itemUrl, nodes: nestedNodes, resourceModificationDate: modificationDate)
                } else {
                    let size = attr[.size] as? Int ?? 0
                    return File(url: itemUrl, size: size, resourceModificationDate: modificationDate)
                }
            }
        } catch {
            return []
        }
    }
    
    func deleteNode(_ node: FSNode) throws {
        try removeItem(at: node.url)
    }
}
