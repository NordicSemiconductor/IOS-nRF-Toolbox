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
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
        ForEach(viewModel.messages.prefix(4), id: \.timestamp) { message in
            UARTMessageView(message)
                .listRowSeparator(.hidden)
        }
        
        if viewModel.messages.isEmpty {
            Label("No messages", systemImage: "info.circle")
                .foregroundStyle(.secondary)
        }
    }
}
