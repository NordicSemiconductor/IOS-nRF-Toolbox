//
//  UARTPresets+XML.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import AEXML
import iOS_Common_Libraries

// MARK: - UARTPresets

extension UARTPresets {
    
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
                commands.append(UARTPreset(i, data: Data(text.utf8), symbol: image, eol: eol))
            } else {
                commands.append(UARTPreset(i, command: text, symbol: image, eol: eol))
            }
        }
        
        for i in commands.count..<UARTPresets.numberOfCommands {
            commands.append(UARTPreset(i))
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
            "length": "\(UARTPresets.numberOfCommands)"
        ])
        commands.addChildren(self.commands.compactMap {
            $0.xml
        })
        root.addChild(commands)
        doc.addChild(root)
        return doc
    }
    
    func saveToFile() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("yourFileName.txt")
        if let data = xml.string.data(using: .utf8) {
            do {
                try data.write(to: fileURL, options: [.atomicWrite])
                print("File saved successfully at: \(fileURL)")
            } catch {
                print("Error saving file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UARTPreset

extension UARTPreset {
    
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
