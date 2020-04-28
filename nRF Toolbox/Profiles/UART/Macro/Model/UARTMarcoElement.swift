//
//  UARTMarcoElement.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol UARTMacroElement {  }

struct UARTMacroTimeInterval: Codable, UARTMacroElement {
    var milliseconds: Int
}
