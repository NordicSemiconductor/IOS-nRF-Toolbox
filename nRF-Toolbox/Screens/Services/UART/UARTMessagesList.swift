//
//  UARTMessagesList.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - UARTMessagesList

struct UARTMessagesList: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
        VStack {
            List {
                Section("Oldest First") {
                    ForEach(viewModel.messages, id: \.timestamp) { message in
                        UARTMessageView(message)
                            .listRowSeparator(.hidden)
                    }
                    
                    Text("...")
                }
            }
            .listRowInsets(EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
            .listRowSpacing(0.0)
            
            UARTSendMessageView()
                .padding(.horizontal, 20)
        }
        .navigationTitle("UART Messages")
        .toolbar {
            Button("", systemImage: "list.bullet.rectangle.portrait") {
                Task { @MainActor in
                    viewModel.clearReceivedMessages()
                }
            }
        }
    }
}

