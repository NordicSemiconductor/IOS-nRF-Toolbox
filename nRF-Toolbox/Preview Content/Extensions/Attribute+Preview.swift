//
//  Attribute+Preview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 24/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Bluetooth_Numbers_Database

#if DEBUG
extension Service: Attribute {
    var level: UInt { 1 }
    var children: [any Attribute] { [] }
}

extension Characteristic: Attribute {
    var id: String {
        UUID().uuidString
    }
    
    var level: UInt { 2 }
    var children: [any Attribute] { [] }
}

extension Descriptor: Attribute {
    var id: String {
        UUID().uuidString
    }
    
    var level: UInt { 3 }
    var children: [any Attribute] { [] }
}
#endif
