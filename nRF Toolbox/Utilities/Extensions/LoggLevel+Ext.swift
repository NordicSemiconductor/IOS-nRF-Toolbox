//
//  LoggLevel+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 23.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIColor

extension LogType {
    var color: UIColor {
        switch self {
        case .warning: return .nordicFall
        case .application: return .nordicGreen
        case .info: return UIColor.Text.systemText
        case .verbose: return .nordicFall
        case .debug, .default:
            return .nordicLake
        case .error, .fault:
            return .nordicRed
        default:
            return UIColor.Text.systemText
        }
    }
}
