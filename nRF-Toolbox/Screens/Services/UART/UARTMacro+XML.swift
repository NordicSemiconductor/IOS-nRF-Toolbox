//
//  UARTMacro+XML.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import AEXML

// MARK: - UARTMacro

extension UARTMacro {
    
    enum XMLError: Error {
        case wrongXMLFormat
    }
    
    // MARK: init (Import)
    
    init(data: Data) throws {
        let document = try AEXMLDocument(xml: data)
        let children = document.children
        guard let rootNode = children.first(where: { (e) -> Bool in
            e.name == "uart-configuration"
        }) else {
            throw XMLError.wrongXMLFormat
        }
        
        name = rootNode.attributes["name"] ?? ""
        guard let commandsNode = rootNode.children.first(where: { $0.name == "commands" }) else {
            throw XMLError.wrongXMLFormat
        }
        
        var commands: [UARTMacroCommand] = []
        commands.reserveCapacity(UARTMacro.numberOfCommands)
        for (i, node) in commandsNode.children.enumerated() where i < UARTMacro.numberOfCommands {
            guard let text = node.value else {
                commands.append(UARTMacroCommand(i))
                continue
            }
            
            // TODO: Pending.
//            let image = CommandImage(name: (node.attributes["icon"] ?? ""), modernIcon: node.attributes["system_icon"].map({ ModernIcon(name: $0) }))
//
//            if let type = node.attributes["type"], type == "data" {
//                commands.append(DataCommand(data: Data(text.hexa), image: image))
//            } else {
//                commands.append(TextCommand(text: text, image: image))
//            }
        }
        
        for i in commands.count..<UARTMacro.numberOfCommands {
            commands.append(UARTMacroCommand(i))
        }
        
        self.commands = commands
    }
    
    // MARK: xml (Export)
    
    var xml: AEXMLDocument {
        let doc = AEXMLDocument()
        let root = AEXMLElement(name: "uart-configuration", attributes: [
            "name": name
        ])
        let commands = AEXMLElement(name: "commands", attributes: [
            "length": "9"
        ])
        commands.addChildren(self.commands.map {
            $0.xml
        })
        root.addChild(commands)
        doc.addChild(root)
        
        return doc
    }
}

// MARK: - UARTMacroCommand

extension UARTMacroCommand {
    
    var xml: AEXMLElement {
        AEXMLElement(name: "command", value: command, attributes: [
            "icon": symbol,
            "active": "true",
            "eol": eol.description,
            "type": "text",
            "system_icon": ""
        ])
    }
}
