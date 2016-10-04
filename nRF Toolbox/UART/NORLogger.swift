//
//  NORLogger.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

enum NORLOGLevel {
    case debugLogLevel
    case verboseLogLevel
    case infoLogLevel
    case appLogLevel
    case warningLogLevel
    case errorLogLevel
}

protocol NORLogger {
    func log(level aLevel: NORLOGLevel, message aMessage: String) -> Void
}
