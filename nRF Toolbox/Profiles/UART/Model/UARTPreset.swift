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
import AEXML

struct UARTPreset {
    
    enum Error: Swift.Error {
        case wrongXMLFormat
    }
    
    var commands: [UARTCommandModel] = Array(repeating: EmptyModel(), count: 9)
    var name: String
    
    var document: AEXMLDocument {
        let doc = AEXMLDocument()
        let root = AEXMLElement(name: "uart-configuration", attributes: [
            "name":name
        ])
        let commands = AEXMLElement(name: "commands", attributes: [
            "length":"9"
        ])
        commands.addChildren(self.commands.map { $0.xml })
        root.addChild(commands)
        doc.addChild(root)
        
        return doc
    }
    
    mutating func updateCommand(_ command: UARTCommandModel, at index: Int) {
        commands[index] = command
    }
    
    init(commands: [UARTCommandModel], name: String) {
        self.commands = commands
        self.name = name
    }
    
    init(data: Data) throws {
        let document = try AEXMLDocument(xml: data)
        let children = document.children
        guard let rootNode = children.first(where: { (e) -> Bool in
            e.name == "uart-configuration"
        }) else {
            throw Error.wrongXMLFormat
        }
        
        name = rootNode.attributes["name"] ?? ""
        guard let commandsNode = rootNode.children.first(where: { $0.name == "commands" }) else {
            throw Error.wrongXMLFormat
        }
        
        var commands: [UARTCommandModel] = []
        for node in commandsNode.children {
            guard commands.count < 9 else {
                break
            }
            
            guard let text = node.value else {
                commands.append(EmptyModel())
                continue
            }
            
            let eol: EOL
            if let eolName = node.attributes["eol"] {
                eol = EOL(name: eolName)
            } else {
                eol = .none
            }
            
            let image = CommandImage(name: (node.attributes["icon"] ?? ""), modernIcon: node.attributes["system_icon"].map({ModernIcon(name: $0)}))

            if let type = node.attributes["type"], type == "data" {
                commands.append(DataCommand(data: Data(text.hexa), image: image))
            } else {
                commands.append(TextCommand(text: text, image: image, eol: eol))
            }

        }
        
        while commands.count < 9 {
            commands.append(EmptyModel())
        }
        
        self.commands = commands
    }
}

extension UARTPreset {
    static let `default` = UARTPreset(commands: [
        DataCommand(data: Data([0x01]), image: .number1),
        DataCommand(data: Data([0x02]), image: .number2),
        DataCommand(data: Data([0x03]), image: .number3),
        TextCommand(text: "Pause", image: .pause),
        TextCommand(text: "Play", image: .play),
        TextCommand(text: "Stop", image: .stop),
        TextCommand(text: "Rew", image: .rewind),
        TextCommand(text: "Start", image: .start),
        TextCommand(text: "Repeat", image: .repeat)
    ], name: "Demo")
    
    static let empty = UARTPreset(commands: Array(repeating: EmptyModel(), count: 9), name: "")
}

extension UARTPreset: Codable {
    enum CodingKeys: String, CodingKey {
        case commands, name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let commandContainers = try container.decode([UARTCommandContainer].self, forKey: .commands)
        commands = commandContainers.compactMap { $0.command as? UARTCommandModel }
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        let modelContainers = commands.map { UARTCommandContainer($0) }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modelContainers, forKey: .commands)
        try container.encode(name, forKey: .name)
    }
}
