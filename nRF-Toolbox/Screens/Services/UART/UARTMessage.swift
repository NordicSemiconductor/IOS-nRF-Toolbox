//
//  UARTMessage.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - UARTMessage

struct UARTMessage {
    
    let text: String
    let source: Source
    let timestamp: Date
    
    init(text: String, source: Source) {
        self.text = text
        self.source = source
        self.timestamp = .now
    }
}

// MARK: - Source

extension UARTMessage {
    
    enum Source {
        case user
        case other
    }
}
