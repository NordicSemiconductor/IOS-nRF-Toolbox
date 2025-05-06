//
//  UARTMessage.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTMessage

struct UARTMessage {
    
    // MARK: Properties
    
    let text: String
    let source: Source
    let timestamp: Date
    let showTimestamp: Bool
    
    // MARK: init
    
    init(text: String, source: Source, previousMessage: Self?) {
        self.text = text
        self.source = source
        let now = Date.now
        self.timestamp = now
        if let previousMessage {
            let previousDateComponents = Calendar.current.dateComponents([.minute],from: previousMessage.timestamp)
            let nowComponents = Calendar.current.dateComponents([.minute], from: now)
            self.showTimestamp = previousDateComponents.minute != nowComponents.minute
        } else {
            self.showTimestamp = true
        }
    }
    
    // MARK: API
    
    var associatedColor: Color {
        switch source {
        case .user:
            return .nordicBlue
        case .other:
            return .green
        }
    }
}

// MARK: - Source

extension UARTMessage {
    
    enum Source {
        case user
        case other
    }
}
