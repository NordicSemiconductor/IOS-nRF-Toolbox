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
    
    // MARK: Properties
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        LabeledContent("MTU (in bytes)") {
            TextField("MTU Size here", value: $viewModel.mtu, formatter: Self.formatter)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 125)
        }
        .labeledContentStyle(.accentedContent(
            accentColor: viewModel.inProgress ? .nordicMiddleGrey: .universalAccentColor,
            lineLimit: 1
        ))
        .disabled(viewModel.inProgress)
        
        LabeledContent("Test Size (in kB)") {
            TextField("Test Size here", value: $viewModel.testSize.value, formatter: Self.formatter)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .frame(maxWidth: 125)
        }
        .labeledContentStyle(.accentedContent(
            accentColor: viewModel.inProgress ? .nordicMiddleGrey: .universalAccentColor,
            lineLimit: 1
        ))
        .disabled(viewModel.inProgress)
        
        Button {
            viewModel.runTest()
        } label: {
            Label(viewModel.inProgress ? "Stop" : "Run",
                  systemImage: viewModel.inProgress ? "stop.fill" : "play.fill")
        }
        .buttonStyle(.plain)
        .centered()
        
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
