//
//  Flag.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct Flag: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt8
    
    let flag: IntegerLiteralType
    
    init(integerLiteral value: UInt8) {
        flag = value
    }
    
    static func isAvailable(bits: UInt8, flag: Flag) -> Bool {
        return bits & flag.flag != 0
    }
}
