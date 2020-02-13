//
//  DFU.LogLevel+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 13/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import iOSDFULibrary

extension LogLevel {
    var level: LOGLevel {
        switch self {
        case .application: return .appLogLevel
        case .debug: return .debugLogLevel
        case .error: return .errorLogLevel
        case .info: return .infoLogLevel
        case .verbose: return .verboseLogLevel
        case .warning: return .warningLogLevel
        }
    }
}
