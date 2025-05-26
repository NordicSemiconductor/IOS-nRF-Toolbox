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
            
            let image = node.attributes["system_icon"] ?? "e.circle"
            let eol: UARTMacroCommand.EndOfLine
            if let eolValue = node.attributes["eol"] {
                eol = UARTMacroCommand.EndOfLine(rawValue: eolValue) ?? .CRLF
            } else {
                eol = .CRLF
            }
            if let type = node.attributes["type"], type == "data" {
                commands.append(UARTMacroCommand(i, data: Data(text.utf8), symbol: image, eol: eol))
            } else {
                commands.append(UARTMacroCommand(i, command: text, symbol: image, eol: eol))
            }
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
            "length": "\(UARTMacro.numberOfCommands)"
        ])
        commands.addChildren(self.commands.compactMap {
            $0.xml
        })
        root.addChild(commands)
        doc.addChild(root)
        
        return doc
    }
}

// MARK: - UARTMacroCommand

extension UARTMacroCommand {
    
    var xml: AEXMLElement? {
        guard let data else { return nil }
        // Add 'prepend0x' to escape Xcode Build Issues and then remove it.
        // I know. Definitely not the best. Hopefully Xcode gets better at disambiguation soon (WWDC).
        let dataString = data.hexEncodedString(options: [Data.HexEncodingOptions.upperCase, Data.HexEncodingOptions.prepend0x]).replacingOccurrences(of: "0x", with: "")
        return AEXMLElement(name: "command", value: dataString, attributes: [
            "icon": symbol,
            "active": "true",
            "eol": eol.description,
            "type": "data",
            "system_icon": symbol
        ])
    }
}
