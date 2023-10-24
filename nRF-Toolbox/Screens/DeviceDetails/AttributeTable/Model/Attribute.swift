//
//  Attribute.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 24/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Bluetooth_Numbers_Database

protocol Attribute  {
    var level: UInt { get }
    var name: String { get }
    var uuidString: String { get }
    var id: String { get }
}

