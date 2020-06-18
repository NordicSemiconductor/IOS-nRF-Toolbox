//
//  UARTCommandModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTCommandModel: UARTMacroElement {
    var data: Data { get }
    var icon: CommandImage? { get }
    var title: String { get }
}

extension UARTCommandModel {
    var image: UIImage? {
        return icon?.image
    }
}

struct UARTCommandModelKey {
    static let titleKey = "UARTCommandModel.Key.title"
    static let iconKey = "UARTCommandModel.Key.icon"
    static let dataKey = "UARTCommandModel.Key.data"
}
