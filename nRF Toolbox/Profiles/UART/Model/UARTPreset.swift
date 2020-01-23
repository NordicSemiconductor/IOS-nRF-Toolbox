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
        doc.addChild(commands)
        
        return doc
    }
    
    mutating func updateCommand(_ command: UARTCommandModel, at index: Int) {
        commands[index] = command
    }
}

extension UARTPreset {
    static let `default` = UARTPreset(commands: [
        DataCommand(data: Data([0x01]), image: .number1),
        DataCommand(data: Data([0x02]), image: .number1),
        DataCommand(data: Data([0x03]), image: .number1),
        TextCommand(text: "Pause", image: .pause),
        TextCommand(text: "Play", image: .play),
        TextCommand(text: "Stop", image: .stop),
        TextCommand(text: "Rew", image: .rewind),
        TextCommand(text: "Start", image: .start),
        TextCommand(text: "Repeat", image: .repeat)
    ], name: "")
}
