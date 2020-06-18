//
//  TextCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class TextCommand: NSObject, UARTCommandModel {
    
    var eol: EOL

    private(set) var data: Data
    private(set) var icon: CommandImage? = nil
    private(set) var title: String = ""

    required init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: UARTCommandModelKey.dataKey) as? Data,
            let eolSymbol = coder.decodeObject(forKey: UARTCommandModelKey.eolSymbol) as? String else {
            return nil
        }

        self.data = data
        self.title = String(data: data, encoding: .utf8) ?? ""
        self.icon = coder.decodeObject(forKey: UARTCommandModelKey.iconKey) as? CommandImage
    }

    func encode(with coder: NSCoder) {
        coder.encode(eol.rawValue, forKey: UARTCommandModelKey.eolSymbol)
        coder.encode(data, forKey: UARTCommandModelKey.dataKey)
        icon.flatMap { coder.encode($0, forKey: UARTCommandModelKey.iconKey) }
    }

}

fileprivate extension UARTCommandModelKey {
    static let eolSymbol = "UARTCommandModel.Key.eolSymbol"
}
