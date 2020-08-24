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
/*
class UARTMacroFileManager {
    
    enum Error: Swift.Error {
        case noDataAtUrl
    }
    
    private var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func save(_ macro: UARTMacro, shodUpdate: Bool = false) throws {
        let data = try JSONEncoder().encode(macro)
        let fileUrl = try self.fileUrl(for: macro.name)
        
        guard !fileManager.fileExists(atPath: fileUrl.path) || shodUpdate else {
            throw QuickError(message: "Macro with that name already exists")
        }
        
        try data.write(to: fileUrl)
    }
    
    func remove(macro: UARTMacro) throws {
        try removeMacro(name: macro.name)
    }
    
    func removeMacro(name: String) throws {
        let url = try fileUrl(for: name)
        try fileManager.removeItem(at: url)
    }
    
    func macrosList() throws -> [String] {
        try fileManager
            .contentsOfDirectory(atPath: macrosDir().path)
            .compactMap { URL(string: $0)?.deletingPathExtension().lastPathComponent }
    }
    
    func macros(for name: String) throws -> UARTMacro {
        let path = try fileUrl(for: name).path
        guard let data = fileManager.contents(atPath: path) else {
            throw Error.noDataAtUrl
        }
        
        return try JSONDecoder().decode(UARTMacro.self, from: data)
    }
    
    private func macrosDir() throws -> URL {
        return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("macros")
    }
    
    private func fileUrl(for name: String) throws -> URL {
        let documentDirectory = try macrosDir()
        if !fileManager.fileExists(atPath: documentDirectory.path) {
            try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return documentDirectory.appendingPathComponent(name).appendingPathExtension("json")
    }
    
}
*/
