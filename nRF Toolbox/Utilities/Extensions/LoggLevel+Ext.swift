//
//  LoggLevel+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 23.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOSDFULibrary

extension LogLevel {
    var color: UIColor {
        switch self {
        case .warning: return .nordicFall
        case .error: return .nordicRed
        case .application: return .nordicGreen
        case .info: return UIColor.Text.systemText
        case .verbose: return .nordicFall
        case .debug: return .nordicLake
        default:
            if #available(iOS 13, *) {
                return .label
            } else {
                return .black
            }
        }
    }
}
