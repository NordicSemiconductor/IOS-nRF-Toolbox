//
//  LogDb.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation

@Model
final class LogDb {
    var value: String
    var timestamp: Date = Date()
    
    init(value: String) {
        self.value = value
    }
}
