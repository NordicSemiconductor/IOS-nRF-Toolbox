//
//  LoggLevel+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 23.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIColor

extension LOGLevel {
    var color: UIColor {
        switch self {
        case .warningLogLevel: return .nordicFall
        case .errorLogLevel: return .nordicRed
        case .appLogLevel: return .nordicGreen
        case .infoLogLevel: return UIColor.Text.systemText
        case .verboseLogLevel: return .nordicFall
        case .debugLogLevel: return .nordicLake
        }
    }
}
