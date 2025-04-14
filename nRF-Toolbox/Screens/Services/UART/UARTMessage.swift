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
    
    // MARK: init
    
    init(text: String, source: Source) {
        self.text = text
        self.source = source
        self.timestamp = .now
    }
    
    // MARK: API
    
    var associatedColor: Color {
        switch source {
        case .user:
            return .nordicBlue
        case .other:
            return .nordicGrass
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
