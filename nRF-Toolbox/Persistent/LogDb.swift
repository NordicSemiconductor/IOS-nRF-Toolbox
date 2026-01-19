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
    var level: Int
    var timestamp: Date
    
    init(value: String, level: Int, timestamp: Date) {
        self.value = value
        self.level = level
        self.timestamp = timestamp
    }
    
    init(value: String, level: LogLevel, timestamp: Date) {
        self.value = value
        self.level = level.rawValue
        self.timestamp = timestamp
    }
    
    convenience init(value: String, level: LogLevel) {
        self.init(value: value, level: level, timestamp: Date())
    }

    func copy() -> LogDb {
        return LogDb(value: self.value, level: self.level, timestamp: self.timestamp)
    }
}

extension LogDb {
    
    private static let formatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    var logLevel: LogLevel {
        LogLevel(rawValue: level)!
    }
    
    var displayDate: String {
        LogDb.formatter.string(from: timestamp)
    }
    
    var displayString: String {
        "\(displayDate): \(logLevel.name) - \(value)"
    }
}

extension LogLevel {
    var name: String {
        switch self {
        case .debug:   return "debug"
        case .info:    return "info"
        case .error:   return "error"
        }
    }
    
    var color: Color {
        switch self {
        case .debug:   return .nordicBlue
        case .info:    return .nordicGrass
        case .error:   return .nordicRed
        }
    }
}
