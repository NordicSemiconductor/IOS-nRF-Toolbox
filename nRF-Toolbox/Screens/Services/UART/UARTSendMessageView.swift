//
//  UARTSendMessageView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 6/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct UARTSendMessageView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
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
    }
}
