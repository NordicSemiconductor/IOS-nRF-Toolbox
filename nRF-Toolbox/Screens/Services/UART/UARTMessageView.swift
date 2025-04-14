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
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM yyyy HH:mm:ss")
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
            VStack(alignment: message.source == .user ? .leading : .trailing) {
                Text(Self.dateFormatter.string(from: message.timestamp))
                    .font(.caption)
                
                Text(message.text)
                    .foregroundStyle(message.associatedColor)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
