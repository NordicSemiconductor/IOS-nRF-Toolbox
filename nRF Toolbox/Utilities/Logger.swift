//
//  Logger.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

enum LOGLevel: CaseIterable {
    case debugLogLevel
    case verboseLogLevel
    case infoLogLevel
    case appLogLevel
    case warningLogLevel
    case errorLogLevel
}

extension LOGLevel {
    var name: String {
        switch self {
        case .appLogLevel: return "Application"
        case .debugLogLevel: return "Debug"
        case .errorLogLevel: return "Error"
        case .infoLogLevel: return "Info"
        case .verboseLogLevel: return "Verbose"
        case .warningLogLevel: return "Warning"
        }
    }
}

protocol Logger {
    func log(level aLevel: LOGLevel, message aMessage: String) -> Void
}
