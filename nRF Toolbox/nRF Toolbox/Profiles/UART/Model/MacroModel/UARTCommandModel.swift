//
//  UARTCommandModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTCommandModel: UARTMacroElement {//, NordicTextTableViewCellModel {
    var data: Data { get }
    var icon: CommandImage? { get }
    var title: String { get }
    
    func clone() -> UARTCommandModel
}

extension UARTCommandModel {
    var image: UIImage? {
        return icon?.image
    }
    
    var text: String? {
        return title
    }
    
    var typeName: String {
        return {
            switch self {
            case is TextCommand: return "Text Command"
            case is DataCommand: return "Data Command"
            default: return ""
            }
        }()
    }
}

struct UARTCommandModelKey {
    static let titleKey = "UARTCommandModel.Key.title"
    static let iconKey = "UARTCommandModel.Key.icon"
    static let dataKey = "UARTCommandModel.Key.data"
}
