//
//  EOL.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 28.05.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

public enum EOL: String {
    case lf = "\n"
    case cr = "\r"
    case lfcr = "\n\r"
    case none = ""
    
    init(symbol: String) {
        switch symbol {
        case "\n": self = .lf
        case "\r": self = .cr
        case "\n\r": self = .lfcr
        default:
            self = .none
        }
    }
}

extension EOL: CaseIterable {
    public static var allCases: [EOL] { [.lf, .cr, .lfcr] }
}
