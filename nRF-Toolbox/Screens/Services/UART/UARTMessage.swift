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

struct UARTMessage: Equatable {
    
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
            let previousDateComponents = Calendar.current.dateComponents([.hour, .minute],from: previousMessage.timestamp)
            let nowComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
            self.showTimestamp = previousDateComponents.hour != nowComponents.hour
                || previousDateComponents.minute != nowComponents.minute
        } else {
            self.showTimestamp = true
        }
    }
    
    // MARK: Private
    
    private var associatedColor: Color {
        switch source {
        case .user:
            return .nordicBlue
        case .other:
            return .green
        }
    }
}

// MARK: - View

extension UARTMessage: View {
    
    var body: some View {
        Text(text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(associatedColor.opacity(0.75),
                        in: RoundedRectangle(cornerRadius: 18.0, style: .continuous))
    }
}

// MARK: - Source

extension UARTMessage {
    
    enum Source {
        case user
        case other
    }
}
