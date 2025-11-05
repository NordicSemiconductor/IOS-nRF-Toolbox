//
//  UARTPresets.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 7/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTPresets

struct UARTPresets: Identifiable, Codable, Hashable, Equatable, CustomStringConvertible {
    
    // MARK: Unselected
    
    static let none = UARTPresets("No Selection")
    
    // MARK: Constants
    
    static let numberOfCommands = 9
    
    // MARK: Properties
    
    var name: String
    let commands: [UARTPreset]
    
    var url: URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent(name)
    }
    
    var id: String { name }
    var description: String { name }
    
    // MARK: Init
    
    init(_ name: String, commands: [UARTPreset]? = nil) {
        self.name = name.isEmpty ? "Unnamed Presets" : name
        if let commands {
            self.commands = commands
        } else {
            var emptyCommands = [UARTPreset]()
            emptyCommands.reserveCapacity(Self.numberOfCommands)
            for i in 0..<Self.numberOfCommands {
                emptyCommands.append(UARTPreset(i))
            }
            self.commands = emptyCommands
        }
    }
}

// MARK: - UARTPreset

struct UARTPreset: Identifiable, Codable, Hashable, Equatable {
    
    // MARK: Properties
    
    let id: Int
    let data: Data?
    let symbol: String
    let eol: EndOfLine
    let type: CommandType
    
    // MARK: init
    
    init(_ id: Int, command: String = "", symbol: String = "e.circle", eol: EndOfLine = .CRLF) {
        self.init(id, data: command.isEmpty ? nil : Data(command.appending(eol.rawValue).utf8), symbol: symbol, eol: eol, type: .text)
    }
    
    init(_ id: Int, data: Data?, symbol: String, eol: EndOfLine, type: CommandType) {
        self.id = id
        self.data = data
        self.symbol = symbol
        self.eol = eol
        self.type = type
    }
    
    // MARK: API
    
    func toString() -> String? {
        guard let data else { return nil }
        if let dataAsString = String(data: data, encoding: .utf8) {
            return dataAsString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        } else {
            return data.hexEncodedString(options: [Data.HexEncodingOptions.upperCase, Data.HexEncodingOptions.prepend0x])
        }
    }
}

// MARK: - CommandType

extension UARTPreset {
    
    enum CommandType: String, RawRepresentable, Codable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case data
        case text
        
        var description: String { rawValue }
    }
}

// MARK: - EOL

extension UARTPreset {
    
    enum EndOfLine: String, Codable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case none = ""
        case LF = "\n"
        case CR = "\r"
        case CRLF = "\r\n"
        
        var description: String {
            switch self {
            case .none:
                return "None"
            case .LF:
                return "LF"
            case .CR:
                return "CR"
            case .CRLF:
                return "CR+LF"
            }
        }
    }
}
