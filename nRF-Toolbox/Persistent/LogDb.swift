//
//  LogDb.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
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

extension LogDb {
    private static let formatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    var levelName: String {
        switch level {
        case .debug:   return "debug"
        case .info:    return "info"
        case .error:   return "error"
        }
    }
    
    var levelColor: Color {
        switch level {
        case .debug:   return .nordicBlue
        case .info:    return .nordicGrass
        case .error:   return .nordicRed
        }
    }
    
    var displayDate: String {
        LogDb.formatter.string(from: timestamp)
    }
    
    var displayString: String {
        "\(displayDate): \(levelName) - \(value)"
    }
}
