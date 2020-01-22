//
//  UARTCommandModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 13.01.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIImage

protocol UARTCommandModel: Codable {
    var image: CommandImage { get }
    var title: String { get }
    var data: Data { get }
}

struct EmptyModel: UARTCommandModel, Codable {
    let image: CommandImage = .empty
    let title: String = ""
    let data: Data = Data()
    
    init() { }
    init(from decoder: Decoder) throws { }
    func encode(to encoder: Encoder) throws { }
}

struct TextCommand: UARTCommandModel, Codable {
    var title: String { text }
    
    var data: Data {
        return text.data(using: .utf8)!
    }
    
    let text: String
    let image: CommandImage
}

struct DataCommand: UARTCommandModel, Codable {
    var title: String { "0x" + data.hexEncodedString().uppercased() }
    
    let data: Data
    let image: CommandImage
}
