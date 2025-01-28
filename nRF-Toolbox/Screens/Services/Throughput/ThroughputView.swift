//
//  ThroughputView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 27/1/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - ThroughputView

struct ThroughputView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: ThroughputViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.inProgress {
            HStack {
                ProgressView()
             
                Text("In Progress...")
            }
            .centered()
            .listRowSeparator(.hidden)
            
            IndeterminateProgressView()
                .listRowSeparator(.hidden)
        }
        
        Button {
            viewModel.toggle()
        } label: {
            Label(viewModel.inProgress ? "Stop" : "Start",
                  systemImage: viewModel.inProgress ? "stop.fill" : "play.fill")
        }
        .centered()
        .listRowSeparator(.hidden)
        
        Divider()
            .listRowSpacing(0)
        
        Label("Number of Writes: \(viewModel.numberOfWrites.nilDescription)", systemImage: "number")
            .listRowSeparator(.hidden)
        
        Label("Bytes Received: \(viewModel.bytesReceived.nilDescription)", systemImage: "")
            .listRowSeparator(.hidden)
        
        Label("Bits/second: \(viewModel.throughputBitsPerSecond.nilDescription)", systemImage: "")
            .listRowSeparator(.hidden)
        
        Button {
            viewModel.read()
        } label: {
            Label("Read", systemImage: "list.clipboard")
        }
        .centered()
    }
}
