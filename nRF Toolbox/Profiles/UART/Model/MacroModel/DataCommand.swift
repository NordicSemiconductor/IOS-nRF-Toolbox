//
//  DataCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DataCommand: NSObject, UARTCommandModel {
    private(set) var data: Data
    private(set) var icon: CommandImage? = nil
    private(set) var title: String = ""

    func encode(with coder: NSCoder) {
        coder.encode(data, forKey: Key.dataKey)
        icon.flatMap { coder.encode($0, forKey: Key.iconKey) }
    }

    required init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: Key.dataKey) as? Data else {
            return nil
        }

        self.data = data
        self.title = "0x" + data.hexString
        self.icon = coder.decodeObject(forKey: Key.iconKey) as? CommandImage
    }
}
