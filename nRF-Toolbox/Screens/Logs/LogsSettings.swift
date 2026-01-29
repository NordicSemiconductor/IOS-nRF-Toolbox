//
//  LogsSettings.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 08/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

@Observable
class LogsSettings {
    private let flagKey = "logs-enabled"
    private let defaults = UserDefaults.standard

    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: flagKey)
        }
    }

    init() {
        if defaults.object(forKey: flagKey) == nil {
            defaults.set(true, forKey: flagKey)
            self.isEnabled = true
        } else {
            self.isEnabled = defaults.bool(forKey: flagKey)
        }
    }
}
