//
//  UARTCommandModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 13.01.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTCommandModel {
    var image: UIImage? { get }
    var imageName: String { get }
    var title: String { get }
    var data: Data { get }
}

struct EmptyModel: UARTCommandModel {
    var image: UIImage? { nil }
    var imageName: String { "" }
    var title: String { "" }
    var data: Data { Data() }
}

struct TextCommand: UARTCommandModel {
    var image: UIImage? { UIImage(named: imageName) }
    var title: String { text }
    
    var data: Data {
        return text.data(using: .utf8)!
    }
    
    let text: String
    let imageName: String
    
    init(text: String, imageName: String) {
        self.imageName = imageName
        self.text = text
    }
}

struct DataCommand: UARTCommandModel {
    var image: UIImage? { UIImage(named: imageName) }
    var title: String { "0x" + data.hexEncodedString().uppercased() }
    
    let data: Data
    let imageName: String
    
    init(data: Data, imageName: String) {
        self.data = data
        self.imageName = imageName
    }
    
}
