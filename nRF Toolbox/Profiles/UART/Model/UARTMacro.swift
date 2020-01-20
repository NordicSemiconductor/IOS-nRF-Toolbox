//
//  UARTMacro.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct UARTMacro {
    let name: String
    let timeInterval: TimeInterval
    let commands: [UARTCommandModel]
}
