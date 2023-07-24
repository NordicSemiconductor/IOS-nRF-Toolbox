//
//  String+Name.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 20/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension Optional where Wrapped == String {
    var deviceName: String {
        switch self {
        case .none: return "unnamed device"
        case .some(let s): return s 
        }
    }
}
