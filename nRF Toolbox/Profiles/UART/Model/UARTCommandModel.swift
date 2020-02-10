//
//  UARTCommandModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 13.01.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import AEXML

protocol UARTCommandModel: Codable, XMLRepresentable, UARTMacroElement, NordicTextTableViewCellModel {
    var image: CommandImage { get }
    var title: String { get }
    var data: Data { get }
}

extension UARTCommandModel {
    var image: UIImage? {
        return self.image.image
    }
    
    var text: String? {
        return self.title
    }
}

protocol XMLRepresentable {
    var xml: AEXMLElement { get }
}

struct EmptyModel: UARTCommandModel {
    var xml: AEXMLElement {
        AEXMLElement(name: "command")
    }
    
    let image: CommandImage = .empty
    let title: String = ""
    let data: Data = Data()
    
    init() { }
    init(from decoder: Decoder) throws { }
    func encode(to encoder: Encoder) throws { }
}

struct TextCommand: UARTCommandModel {
    var xml: AEXMLElement {
        AEXMLElement(name: "command", value: text, attributes: [
            "icon":image.name,
            "active":"true",
            "eol":"CR",
            "type":"text",
            "system_icon":image.systemIcon?.name ?? ""
        ])
    }
    
    var title: String { text }
    
    var data: Data {
        text.data(using: .utf8)!
    }
    
    let text: String
    let image: CommandImage
}

struct DataCommand: UARTCommandModel {
    var xml: AEXMLElement {
        AEXMLElement(name: "command", value: data.hexString, attributes: [
            "icon":image.name,
            "active":"true",
            "eol":"CR",
            "type":"data",
            "system_icon":image.systemIcon?.name ?? ""
        ])
    }
    
    var title: String { "0x" + data.hexEncodedString().uppercased() }
    
    let data: Data
    let image: CommandImage
}
