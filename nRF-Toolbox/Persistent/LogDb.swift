//
//  LogDb.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation
import iOS_Common_Libraries

@Model
final class LogDb {
    var value: String
    var level: LogLevel
    var timestamp: Date = Date()
    
    init(value: String, level: LogLevel) {
        self.value = value
        self.level = level
    }
}
