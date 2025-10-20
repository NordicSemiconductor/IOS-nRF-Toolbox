//
//  UARTSendMessageView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 6/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct UARTSendMessageView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    @FocusState private var isFocused: Bool
    
    // MARK: view
    
    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                
                BlinkingCursorView().hidden(!viewModel.newMessage.isEmpty)

                HStack(spacing: 0) {
                    TextField("UART Message", text: $viewModel.newMessage, prompt: Text("Write new message here")).focused($isFocused).tint(.clear)
                    BlinkingCursorView().hidden()
                }
                
                HStack(spacing: 0) {
                    Text(viewModel.newMessage).lineLimit(1).hidden()
                    BlinkingCursorView().hidden(viewModel.newMessage.isEmpty)
                }
            }

            Button {
                let data = Data(viewModel.newMessage.utf8)
                viewModel.newMessage = ""
                Task {
                    await viewModel.send(data)
                }
            } label: {
                Label("Send", systemImage: "paperplane.fill")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(Color.universalAccentColor)
        }
    }
}
