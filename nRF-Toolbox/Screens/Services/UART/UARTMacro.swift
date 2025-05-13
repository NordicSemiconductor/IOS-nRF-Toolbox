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
    let inEditMode: Bool
    let commands: [UARTMacroCommand]
    
    var id: String { name }
    var description: String { name }
    
    // MARK: Init
    
    init(_ name: String, editMode: Bool = false) {
        self.name = name.isEmpty ? "Unnamed Macro" : name
        self.inEditMode = editMode
        var emptyCommands = [UARTMacroCommand]()
        emptyCommands.reserveCapacity(Self.numberOfCommands)
        for i in 0..<Self.numberOfCommands {
            emptyCommands.append(UARTMacroCommand(i))
        }
        self.commands = emptyCommands
    }
    
    // MARK: API
    
    func editCommand(at index: Int, command: String, symbol: String) {
        let newCommand = UARTMacroCommand(index, command: command, symbol: symbol)
        
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
    
    init(_ id: Int, command: String = "", symbol: String = "e.circle", eol: EndOfLine = .CRLF) {
        self.id = id
        self.command = command
        self.symbol = symbol
        self.eol = eol
    }
}

// MARK: - EOL

extension UARTMacroCommand {
    
    enum EndOfLine: String, Codable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case LF = "\n"
        case CR = "\r"
        case CRLF = "\r\n"
        
        var description: String {
            switch self {
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
