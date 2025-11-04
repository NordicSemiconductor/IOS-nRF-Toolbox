//
//  UARTPresetsXmlParser.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 04/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import iOS_Common_Libraries
import Foundation
import AEXML

enum XMLError: Error {
    case wrongXMLFormat
}

class UARTPresetsXmlParser {
    private let log = NordicLog(category: "UARTViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    func toXml(_ presets: UARTPresets) throws -> String {
        let doc = AEXMLDocument()
        let root = AEXMLElement(name: "uart-configuration", attributes: [
            "name": presets.name
        ])
        let commands = AEXMLElement(name: "commands", attributes: [
            "length": "\(UARTPresets.numberOfCommands)"
        ])
        let children = try presets.commands.compactMap {
            try toXml($0)
        }
        commands.addChildren(children)
        root.addChild(commands)
        doc.addChild(root)
        return doc.xml
    }
    
    private func toXml(_ preset: UARTPreset) throws -> AEXMLElement? {
        let data = preset.data ?? Data()
        
        let dataString = if (preset.type == .data) {
            // Add 'prepend0x' to escape Xcode Build Issues and then remove it.
            // I know. Definitely not the best. Hopefully Xcode gets better at disambiguation soon (WWDC).
            data.hexEncodedString(options: [Data.HexEncodingOptions.upperCase, Data.HexEncodingOptions.prepend0x]).replacingOccurrences(of: "0x", with: "")
        } else {
            String(data: data, encoding: .utf8)
        }
        return AEXMLElement(name: "command", value: dataString, attributes: [
            "icon": preset.symbol,
            "active": "true",
            "eol": preset.eol.description,
            "type": preset.type.rawValue,
            "system_icon": preset.symbol
        ])
    }
    
    func fromXml(_ data: Data) throws -> UARTPresets {
        let document = try AEXMLDocument(xml: data)
        let children = document.children
        guard let rootNode = children.first(where: { (e) -> Bool in
            e.name == "uart-configuration"
        }) else {
            throw XMLError.wrongXMLFormat
        }
        
        let name = rootNode.attributes["name"] ?? ""
        guard let commandsNode = rootNode.children.first(where: { $0.name == "commands" }) else {
            throw XMLError.wrongXMLFormat
        }
        
        var commands: [UARTPreset] = []
        commands.reserveCapacity(UARTPresets.numberOfCommands)
        for (i, node) in commandsNode.children.enumerated() where i < UARTPresets.numberOfCommands {
            guard let text = node.value else {
                commands.append(UARTPreset(i))
                continue
            }
            
            let image = node.attributes["system_icon"] ?? "e.circle"
            let eol: UARTPreset.EndOfLine
            if let eolValue = node.attributes["eol"] {
                eol = UARTPreset.EndOfLine(rawValue: eolValue) ?? .CRLF
            } else {
                eol = .CRLF
            }
            if let type = node.attributes["type"], type == "data" {
                commands.append(UARTPreset(i, data: Data(text.utf8), symbol: image, eol: eol, type: .data))
            } else {
                commands.append(UARTPreset(i, command: text, symbol: image, eol: eol))
            }
        }
        
        for i in commands.count..<UARTPresets.numberOfCommands {
            commands.append(UARTPreset(i))
        }
        
        return UARTPresets(name, commands: commands)
    }
}
