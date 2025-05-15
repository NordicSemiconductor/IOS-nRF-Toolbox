//
//  UARTMacro+XML.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import AEXML

extension UARTMacro {
    
//    var document: AEXMLDocument {
//        let doc = AEXMLDocument()
//        let root = AEXMLElement(name: "uart-configuration", attributes: [
//            "name":name
//        ])
//        let commands = AEXMLElement(name: "commands", attributes: [
//            "length":"9"
//        ])
//        commands.addChildren(self.commands.map { $0.xml })
//        root.addChild(commands)
//        doc.addChild(root)
//        
//        return doc
//    }
//    
//    init(data: Data) throws {
//        let document = try AEXMLDocument(xml: data)
//        let children = document.children
//        guard let rootNode = children.first(where: { (e) -> Bool in
//            e.name == "uart-configuration"
//        }) else {
//            throw Error.wrongXMLFormat
//        }
//        
//        name = rootNode.attributes["name"] ?? ""
//        guard let commandsNode = rootNode.children.first(where: { $0.name == "commands" }) else {
//            throw Error.wrongXMLFormat
//        }
//        
//        var commands: [UARTCommandModel] = []
//        for node in commandsNode.children {
//            guard commands.count < 9 else {
//                break
//            }
//            
//            guard let text = node.value else {
//                commands.append(EmptyModel())
//                continue
//            }
//            
//            let image = CommandImage(name: (node.attributes["icon"] ?? ""), modernIcon: node.attributes["system_icon"].map({ModernIcon(name: $0)}))
//
//            if let type = node.attributes["type"], type == "data" {
//                commands.append(DataCommand(data: Data(text.hexa), image: image))
//            } else {
//                commands.append(TextCommand(text: text, image: image))
//            }
//
//        }
//        
//        while commands.count < 9 {
//            commands.append(EmptyModel())
//        }
//        
//        self.commands = commands
//    }
}
