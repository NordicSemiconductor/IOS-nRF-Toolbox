//
//  Flag.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol Flag {
    var value: Int { get }
}

extension Flag {
    func enabled(at bit: Int) -> Bool {
        (2 ^ bit) & value != 0
    }
}
