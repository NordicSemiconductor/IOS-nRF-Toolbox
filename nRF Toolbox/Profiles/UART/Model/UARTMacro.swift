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
    var commands: [UARTMacroElement]
    var preset: UARTPreset
}

extension UARTMacro {
    static var empty: UARTMacro {
        UARTMacro(name: "", commands: [], preset: .empty)
    }
}

struct UARTCommandContainer: Codable {
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
        type = try container.decode(CommandType.self, forKey: .type)
        switch self.type {
        case .timeInterval:
            command = try container.decode(UARTMacroTimeInterval.self, forKey: .command)
        case .text:
            command = try container.decode(TextCommand.self, forKey: .command)
        case .data:
            command = try container.decode(DataCommand.self, forKey: .command)
        default:
            command = EmptyModel()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        switch command {
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
        case name, preset, commands
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let commandContainers = try container.decode([UARTCommandContainer].self, forKey: .commands)
        preset = try container.decode(UARTPreset.self, forKey: .preset)
        commands = commandContainers.map { $0.command }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(preset, forKey: .preset)
        
        let commandContainers = commands.map(UARTCommandContainer.init)
        try container.encode(commandContainers, forKey: .commands)
    }
}
