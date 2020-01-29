//
//  UARTPreset.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

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
        
        self.name = rootNode.attributes["name"] ?? ""
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
            
            let image = CommandImage(name: (node.attributes["icon"] ?? ""))

            if let type = node.attributes["type"], type == "data" {
                commands.append(DataCommand(data: Data(text.hexa), image: image))
            } else {
                commands.append(TextCommand(text: text, image: image))
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
    ], name: "")
}
