//
//  UARTMacro.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 7/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTMacro

struct UARTMacro: Identifiable, Codable, Hashable, Equatable, CustomStringConvertible {
    
    // MARK: Unselected
    
    static let none = UARTMacro("No Selection")
    
    // MARK: Constants
    
    static let numberOfCommands = 9
    
    // MARK: Properties
    
    let name: String
    let commands: [UARTMacroCommand]
    
    var id: String { name }
    var description: String { name }
    
    // MARK: Init
    
    init(_ name: String, commands: [UARTMacroCommand]? = nil) {
        self.name = name.isEmpty ? "Unnamed Macro" : name
        if let commands {
            self.commands = commands
        } else {
            var emptyCommands = [UARTMacroCommand]()
            emptyCommands.reserveCapacity(Self.numberOfCommands)
            for i in 0..<Self.numberOfCommands {
                emptyCommands.append(UARTMacroCommand(i))
            }
            self.commands = emptyCommands
        }
    }
}

// MARK: - UARTMacroCommand

struct UARTMacroCommand: Identifiable, Codable, Hashable, Equatable {
    
    // MARK: Properties
    
    let id: Int
    let command: String
    let symbol: String
    let eol: EndOfLine
    
    // MARK: init
    
    init(_ id: Int, command: String = "", symbol: String = "e.circle", eol: EndOfLine = .crlf) {
        self.id = id
        self.command = command
        self.symbol = symbol
        self.eol = eol
    }
    
    // MARK: API
    
    func data() -> Data? {
        guard !command.isEmpty else { return nil }
        return Data(command.appending(eol.rawValue).utf8)
    }
}

// MARK: - CommandType

extension UARTMacroCommand {
    
    enum CommandType: String, RawRepresentable, Codable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case data
        case text
        
        var description: String { rawValue }
    }
}

// MARK: - EOL

extension UARTMacroCommand {
    
    enum EndOfLine: String, Codable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case none = ""
        case lf = "\n"
        case cr = "\r"
        case crlf = "\r\n"
        
        var description: String {
            switch self {
            case .none:
                return "None"
            case .lf:
                return "LF"
            case .cr:
                return "CR"
            case .crlf:
                return "CR+LF"
            }
        }
    }
}
