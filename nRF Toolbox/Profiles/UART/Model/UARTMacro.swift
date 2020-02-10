//
//  UARTMacro.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct UARTMacro {
    var name: String
    /// Delay between commands in milliseconds
    var delay: Int
    var commands: [UARTMacroElement]
}

extension UARTMacro {
    static var empty: UARTMacro {
        UARTMacro(name: "", delay: 100, commands: [])
    }
}

private struct UARTCommandContainer: Codable {
    enum CommandType: String, Codable {
        case empty, text, data, timeInterval
    }
    
    enum CodingKeys: String, CodingKey {
        case command, type
    }
    
    let command: UARTMacroElement
    let type: CommandType
    
    init(_ command: UARTMacroElement) {
        self.command = command
        self.type = {
            switch command {
            case is TextCommand: return .text
            case is DataCommand: return .data
            case is UARTMacroTimeInterval: return .timeInterval
            default: return .empty
            }
        }()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(CommandType.self, forKey: .type)
        switch self.type {
        case .timeInterval:
            self.command = try container.decode(UARTMacroTimeInterval.self, forKey: .command)
        case .text:
            self.command = try container.decode(TextCommand.self, forKey: .command)
        case .data:
            self.command = try container.decode(DataCommand.self, forKey: .command)
        default:
            self.command = EmptyModel()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        switch self.command {
        case let m as UARTMacroTimeInterval:
            try container.encode(m, forKey: .command)
        case let m as TextCommand:
            try container.encode(m, forKey: .command)
        case let m as DataCommand:
            try container.encode(m, forKey: .command)
        case let m as EmptyModel:
            try container.encode(m, forKey: .command)
        default:
            break
        }
    }
}

extension UARTMacro: Codable {
    
    enum Error: Swift.Error {
        case cannotParseCommandList
    }
    
    enum CodingKeys: String, CodingKey {
        case name, delay, commands
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.delay = try container.decode(Int.self, forKey: .delay)
        let commandContainers = try container.decode([UARTCommandContainer].self, forKey: .commands)
        self.commands = commandContainers.map { $0.command }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(delay, forKey: .delay)
        
        let commandContainers = commands.map(UARTCommandContainer.init)
        try container.encode(commandContainers, forKey: .commands)
    }
}
