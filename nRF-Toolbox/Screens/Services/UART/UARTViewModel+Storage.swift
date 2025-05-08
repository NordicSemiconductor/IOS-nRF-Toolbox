//
//  UARTViewModel+Storage.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 8/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - Storage

extension UARTViewModel {
    
    static let fileManager = FileManager.default
    
    // MARK: read
    
    static func read() -> [UARTMacro]? {
        let fileUrl = try? self.fileUrl(for: "macros")
        guard let fileUrl, let readData = try? Data(contentsOf: fileUrl) else { return nil }
        let decodedData = try? JSONDecoder().decode([UARTMacro].self, from: readData)
        return decodedData
    }
    
    // MARK: write
    
    static func writeBack(macros: [UARTMacro]) {
        let fileUrl = try? self.fileUrl(for: "macros")
        let jsonData = try? JSONEncoder().encode(macros)
        
        guard let fileUrl, let jsonData else { return }
        try? jsonData.write(to: fileUrl)
    }
    
    private static func macrosDir() throws -> URL {
        return try Self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("macros")
    }
    
    private static func fileUrl(for name: String) throws -> URL {
        let documentDirectory = try macrosDir()
        if !Self.fileManager.fileExists(atPath: documentDirectory.path) {
            try Self.fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return documentDirectory.appendingPathComponent(name).appendingPathExtension("json")
    }
}
