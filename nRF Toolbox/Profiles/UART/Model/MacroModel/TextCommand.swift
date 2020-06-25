//
//  TextCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class TextCommand: NSObject, UARTCommandModel {
    
    private(set) var icon: CommandImage? = nil
    private(set) var title: String = ""
    
    var eol: EOL
    var data: Data {
        title.data(using: .utf8)!
    }

    required init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: UARTCommandModelKey.dataKey) as? Data,
            let eolSymbol = coder.decodeObject(forKey: UARTCommandModelKey.eolSymbol) as? String else {
            return nil
        }

        self.title = String(data: data, encoding: .utf8) ?? ""
        self.icon = coder.decodeObject(forKey: UARTCommandModelKey.iconKey) as? CommandImage
        self.eol = EOL(rawValue: eolSymbol)!
    }
    
    init(text: String, image: CommandImage, eol: EOL = .cr) {
        self.title = text
        self.icon = image
        self.eol = eol
    }

    func encode(with coder: NSCoder) {
        coder.encode(eol.rawValue, forKey: UARTCommandModelKey.eolSymbol)
        coder.encode(data, forKey: UARTCommandModelKey.dataKey)
        icon.flatMap { coder.encode($0, forKey: UARTCommandModelKey.iconKey) }
    }

    func clone() -> UARTCommandModel {
        TextCommand(text: text!, image: icon!, eol: eol)
    }
}

fileprivate extension UARTCommandModelKey {
    static let eolSymbol = "UARTCommandModel.Key.eolSymbol"
}
