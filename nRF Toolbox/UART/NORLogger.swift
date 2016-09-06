//
//  NORLogger.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

enum NORLOGLevel {
    case DebugLogLevel
    case VerboseLogLevel
    case InfoLogLevel
    case AppLogLevel
    case WarningLogLevel
    case ErrorLogLevel
}

protocol NORLogger {
    func log(level aLevel: NORLOGLevel, message aMessage: String) -> Void
}