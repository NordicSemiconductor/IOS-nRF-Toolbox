//
//  LogItemDomain.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 20/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import Foundation
import SwiftData
import iOS_Common_Libraries
import SwiftUI

nonisolated struct LogItemDomain: Equatable {
    var id: UUID = UUID()
    var persistentModelID: PersistentIdentifier?
    
    var value: String
    var level: Int
    var timestamp: Date
}

nonisolated extension LogItemDomain: ProtectedModel {
    init(from item: LogDb) {
        self.init(
            id: item.id,
            persistentModelID: item.persistentModelID,
            value: item.value,
            level: item.level,
            timestamp: item.timestamp
        )
    }
}

extension LogItemDomain {
    
    private static let formatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    var logLevel: LogLevel {
        LogLevel(rawValue: level)!
    }
    
    var displayDate: String {
        LogItemDomain.formatter.string(from: timestamp)
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
