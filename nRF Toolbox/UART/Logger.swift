//
//  Logger.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

enum LOGLevel {
    case debugLogLevel
    case verboseLogLevel
    case infoLogLevel
    case appLogLevel
    case warningLogLevel
    case errorLogLevel
}

protocol Logger {
    func log(level aLevel: LOGLevel, message aMessage: String) -> Void
}
