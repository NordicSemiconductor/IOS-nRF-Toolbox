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
    
    static func fileUrl() throws -> URL {
        try self.fileUrl(for: "presets")
    }
    
    // MARK: read
    
    static func read() throws -> [UARTPresets]? {
        let fileUrl = try self.fileUrl(for: "presets")
        let readData = try Data(contentsOf: fileUrl)
        let decodedData = try? JSONDecoder().decode([UARTPresets].self, from: readData)
        return decodedData
    }
    
    // MARK: write
    
    static func writeBack(presets: [UARTPresets]) throws {
        let fileUrl = try self.fileUrl(for: "presets")
        let jsonData = try JSONEncoder().encode(presets)
        
        try jsonData.write(to: fileUrl)
    }
    
    private static func presetsDir() throws -> URL {
        return try Self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("presets")
    }
    
    private static func fileUrl(for name: String) throws -> URL {
        let documentDirectory = try presetsDir()
        if !Self.fileManager.fileExists(atPath: documentDirectory.path) {
            try Self.fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return documentDirectory.appendingPathComponent(name).appendingPathExtension("json")
    }
}
