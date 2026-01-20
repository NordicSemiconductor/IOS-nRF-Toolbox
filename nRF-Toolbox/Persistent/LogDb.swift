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
    var id: UUID
    var value: String
    var level: Int
    var timestamp: Date
    
    init(id: UUID = UUID(), value: String, level: Int, timestamp: Date) {
        self.id = id
        self.value = value
        self.level = level
        self.timestamp = timestamp
    }
    
    convenience init(from logItem: LogItemDomain) {
        self.init(
            id: logItem.id,
            value: logItem.value,
            level: logItem.level,
            timestamp: logItem.timestamp
        )
    }
}
