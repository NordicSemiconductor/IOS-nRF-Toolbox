//
//  McuMgrLogObserver.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 24.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import McuManager

extension McuMgrLogLevel {
    var level: LogType {
        switch self {
        case .application: return .application
        case .debug: return .debug
        case .error: return .error
        case .info: return .info
        case .verbose: return .verbose
        case .warning: return .warning
        }
    }
}

class McuMgrLogObserver: LogObserver, McuMgrLogDelegate {
    var shouldLog: Bool = true
    
    func log(_ msg: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
        guard shouldLog else { return }
        logWith(level.level, message: msg)
    }
    
    
}
