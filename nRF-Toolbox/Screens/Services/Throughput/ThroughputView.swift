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
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        if viewModel.inProgress {
            HStack {
                ProgressView()
             
                Text("In Progress...")
            }
            .centered()
            .listRowSeparator(.hidden)
            
            IndeterminateProgressView()
                .accentColor(.universalAccentColor)
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
        .fixedListRowSeparatorPadding()
        
        Button {
            Task { @MainActor in
                await viewModel.reset()
            }
        } label: {
            Label("Reset", systemImage: "arrow.uturn.left")
        }
        .fixedListRowSeparatorPadding()
        .buttonStyle(.plain)
        .centered()
    }
    
    // MARK: attributes
    
    private var attributes: [RunningAttribute] {
        var items = [RunningAttribute]()
        let speedKey = "Speed"
        items.append(RunningAttribute(title: speedKey, value: String(format: "%.2f", viewModel.readData.throughputMeasurement().value), unit: "\(viewModel.readData.throughputMeasurement().unit.symbol)/s"))
        
        let countKey = "Count"
        items.append(RunningAttribute(title: countKey, value: "\(viewModel.readData.numberOfWrites)", unit: "writes"))
        
        let dataKey = "Data"
        items.append(RunningAttribute(title: dataKey, value: String(format: "%.2f", viewModel.readData.bytesReceivedMeasurement().value), unit: viewModel.readData.bytesReceivedMeasurement().unit.symbol))
        return items
    }
}
