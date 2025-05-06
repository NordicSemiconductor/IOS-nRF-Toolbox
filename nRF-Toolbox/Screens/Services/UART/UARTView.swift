//
//  UARTView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTView

struct UARTView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
        ForEach(viewModel.messages.prefix(4), id: \.timestamp) { message in
            UARTMessageView(message)
                .listRowSeparator(.hidden)
        }
        
        if viewModel.messages.isEmpty {
            Text("No messages so far")
        }
        
        HStack {
            TextField("UART Message", text: $viewModel.newMessage, prompt: Text("Write new message here"))
                
            Button {
                Task { @MainActor in
                    await viewModel.sendMessage()
                }
            } label: {
                Label("Send", systemImage: "paperplane.fill")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(Color.universalAccentColor)
        }
        .fixedListRowSeparatorPadding()
        
        NavigationLink("All Messages (\(viewModel.messages.count))") {
            UARTMessagesList()
                .environmentObject(viewModel)
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
