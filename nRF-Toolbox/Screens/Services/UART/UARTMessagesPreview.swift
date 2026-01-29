//
//  UARTMessagesPreview.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 6/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - UARTMessagesPreview

struct UARTMessagesPreview: View {
    
    // MARK: EnvironmentObject
    
    @Environment(UARTViewModel.self) private var viewModel: UARTViewModel
    
    // MARK: Properties
    
    private let messages: [UARTMessage]
    
    // MARK: init
    
    init(_ messages: [UARTMessage]) {
        var modified = messages
        if let firstItem = messages.first {
            modified[0] = UARTMessage(text: firstItem.text, source: firstItem.source,
                                      previousMessage: nil)
        }
        self.messages = modified
    }
    
    // MARK: view
    
    var body: some View {
        ForEach(messages, id: \.timestamp) { message in
            UARTMessageView(message)
                .listRowSeparator(.hidden)
        }
        
        if viewModel.messages.isEmpty {
            Label("No messages", systemImage: "info.circle")
                .foregroundStyle(.secondary)
                .listRowSeparator(.hidden)
        }
    }
}
