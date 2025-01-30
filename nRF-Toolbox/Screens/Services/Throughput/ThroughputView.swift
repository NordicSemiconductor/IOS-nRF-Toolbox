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
        if let data = viewModel.readData {
            Label("Writes: \(data.numberOfWrites)", systemImage: "number")
                .listRowSeparator(.hidden)
            
            Label("Received: \(data.bytesReceivedString())", systemImage: "suitcase.cart")
                .listRowSeparator(.hidden)
            
            Label("Speed: \(data.throughputString())", systemImage: "metronome")
                .listRowSeparator(.hidden)
        } else {
            NoContentView(title: "No Data", systemImage: "metronome")
        }
        
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
        
        HStack {
            Button {
                viewModel.toggle()
            } label: {
                Label(viewModel.inProgress ? "Stop" : "Start",
                      systemImage: viewModel.inProgress ? "stop.fill" : "play.fill")
            }
            .buttonStyle(.plain)
            .centered()
            
            Divider()
            
            Button {
                viewModel.read()
            } label: {
                Label("Read", systemImage: "list.clipboard")
            }
            .buttonStyle(.plain)
            .centered()
        }
    }
}
