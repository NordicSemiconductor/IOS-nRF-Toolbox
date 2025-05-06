//
//  UARTMessageView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - UARTMessageView

struct UARTMessageView: View {
    
    // MARK: Private Properties
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    private let message: UARTMessage
    
    // MARK: init
    
    init(_ message: UARTMessage) {
        self.message = message
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            if message.source == .user {
                Spacer()
                
                VStack(alignment: .trailing) {
                    if message.showTimestamp {
                        Text(Self.dateFormatter.string(from: message.timestamp))
                            .font(.caption)
                    }
                    
                    message
                }
            } else {
                VStack(alignment: .leading) {
                    if message.showTimestamp {
                        Text(Self.dateFormatter.string(from: message.timestamp))
                            .font(.caption)
                    }
                    
                    message
                }
                
                Spacer()
            }
        }
    }
}
