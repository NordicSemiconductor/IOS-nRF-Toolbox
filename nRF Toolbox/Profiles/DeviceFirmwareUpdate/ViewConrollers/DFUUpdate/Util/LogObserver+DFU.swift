//
//  LogObserver+DFU.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 24.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOSDFULibrary


class DFULogObserver: LogObserver, LoggerDelegate {
    func logWith(_ level: LogLevel, message: String) {
        logWith(level.level, message: message)
    }
}
