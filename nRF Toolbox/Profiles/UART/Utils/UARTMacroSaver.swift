//
//  UARTMacroSaver.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 18/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class UARTMacroFileManager: NSObject {
    private var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        super.init()
    }
    
    func save(_ macro: UARTMacro, sholdUpdate: Bool = false) throws {
        let data = try JSONEncoder().encode(macro)
        let fileUrl = try self.fileUrl(for: macro)
        
        guard !fileManager.fileExists(atPath: fileUrl.path) || sholdUpdate else {
            throw QuickError(message: "Macro with that name already exists")
        }
        
        try data.write(to: fileUrl)
    }
    
    func remove(macro: UARTMacro) throws {
        let url = try fileUrl(for: macro)
        try fileManager.removeItem(at: url)
    }
    
    func macrosUrls() throws -> [URL] {
        try fileManager
            .contentsOfDirectory(atPath: macrosDir().path)
            .compactMap { URL(string: $0) }
    }
    
    private func macrosDir() throws -> URL {
        return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("macros")
    }
    
    private func fileUrl(for macro: UARTMacro) throws -> URL {
        let documentDirectory = try macrosDir()
        if !fileManager.fileExists(atPath: documentDirectory.path) {
            try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return documentDirectory.appendingPathComponent(macro.name).appendingPathExtension("json")
    }
    
}
