//
//  UARTMacroSaver.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 18/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

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
