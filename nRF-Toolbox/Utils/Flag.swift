//
//  Flag.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct Flag: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt8
    
    let flag: IntegerLiteralType
    
    init(integerLiteral value: UInt8) {
        flag = value
    }
    
    static func isAvailable(bits: UInt8, flag: Flag) -> Bool {
        bits & flag.flag != 0
    }
}
