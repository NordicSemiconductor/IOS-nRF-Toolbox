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
        fatalError()
        /*
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
 */
    }
    
    func encode(to encoder: Encoder) throws {
        fatalError()
        /*
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
 */
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
        fatalError()
        /*
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let commandContainers = try container.decode([UARTCommandContainer].self, forKey: .commands)
        preset = try container.decode(UARTPreset.self, forKey: .preset)
        commands = commandContainers.map { $0.command }
 */
    }
    
    func encode(to encoder: Encoder) throws {
        fatalError()
        /*
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(preset, forKey: .preset)
        
        let commandContainers = commands.map(UARTCommandContainer.init)
        try container.encode(commandContainers, forKey: .commands)
 */
    }
}
*/


