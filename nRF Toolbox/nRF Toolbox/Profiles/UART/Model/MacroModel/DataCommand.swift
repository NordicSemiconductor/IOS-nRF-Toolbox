//
//  DataCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DataCommand: NSObject, UARTCommandModel {

    func clone() -> UARTCommandModel {
        DataCommand(data: data, image: icon!)
    }

    private(set) var data: Data
    private(set) var icon: CommandImage? = nil
    var title: String {
        "0x" + data.hexString
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(data, forKey: UARTCommandModelKey.dataKey)
        icon.flatMap { coder.encode($0, forKey: UARTCommandModelKey.iconKey) }
    }

    required init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: UARTCommandModelKey.dataKey) as? Data else {
            return nil
        }

        self.data = data
        self.icon = coder.decodeObject(forKey: UARTCommandModelKey.iconKey) as? CommandImage
    }
    
    init(data: Data, image: CommandImage) {
        self.data = data
        self.icon = image
    }
}
