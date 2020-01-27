//
//  UARTCommandModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 13.01.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import AEXML

protocol UARTCommandModel: Codable, XMLRepresentable {
    var image: CommandImage { get }
    var title: String { get }
    var data: Data { get }
}

protocol XMLRepresentable {
    var xml: AEXMLElement { get }
}

struct EmptyModel: UARTCommandModel {
    var xml: AEXMLElement {
        return AEXMLElement(name: "command")
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
        return AEXMLElement(name: "command", value: text, attributes: [
            "icon":image.name,
            "active":"true",
            "eol":"CR"
        ])
    }
    
    var title: String { text }
    
    var data: Data {
        return text.data(using: .utf8)!
    }
    
    let text: String
    let image: CommandImage
}

struct DataCommand: UARTCommandModel {
    var xml: AEXMLElement {
        return AEXMLElement(name: "command", value: String(data: data, encoding: .ascii), attributes: [
            "icon":image.name,
            "active":"true",
            "eol":"CR"
        ])
    }
    
    var title: String { "0x" + data.hexEncodedString().uppercased() }
    
    let data: Data
    let image: CommandImage
}