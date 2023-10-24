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
}

extension Characteristic: Attribute {
    var id: String {
        UUID().uuidString
    }
    
    var level: UInt { 2 }
}

extension Descriptor: Attribute {
    var id: String {
        UUID().uuidString
    }
    
    var level: UInt { 3 }
}
#endif
