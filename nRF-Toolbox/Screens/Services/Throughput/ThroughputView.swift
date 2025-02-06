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
    
    enum Field {
        case mtu
        case testSize
        case timeLimit
    }
    
    @FocusState private var focusedField: Field?
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        Group {
            LabeledContent("MTU (in bytes)") {
                TextField("MTU Size here", value: $viewModel.mtu, formatter: Self.formatter)
                    .focused($focusedField, equals: .mtu)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 125)
            }
            
            LabeledContent("Test Size (in kB)") {
                TextField("Test Size here", value: $viewModel.testSize.value, formatter: Self.formatter)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 125)
                .focused($focusedField, equals: .testSize)
                .keyboardType(.decimalPad)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        
                        Button("Done") {
                            focusedField = .none
                        }
                    }
                }
            }
            
            LabeledContent("Set Time Limit") {
                Toggle("", isOn: $viewModel.isTimeLimited)
                    .tint(Color.universalAccentColor)
            }
            
            if viewModel.isTimeLimited {
                LabeledContent("Time Limit (seconds)") {
                    TextField("Time Limit here", value: $viewModel.testTimeLimit.value, formatter: Self.formatter)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 125)
                        .focused($focusedField, equals: .timeLimit)
                        .keyboardType(.numberPad)
                }
            }
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
        
        let durationKey = "Duration"
        items.append(RunningAttribute(title: durationKey, value: String(format: "%.2f", viewModel.testDuration.value), unit: viewModel.testDuration.unit.symbol))
        
        let countKey = "Count"
        items.append(RunningAttribute(title: countKey, value: "\(viewModel.readData.numberOfWrites)", unit: "writes"))
        
        let dataKey = "Data"
        items.append(RunningAttribute(title: dataKey, value: String(format: "%.2f", viewModel.readData.bytesReceivedMeasurement().value), unit: viewModel.readData.bytesReceivedMeasurement().unit.symbol))
        return items
    }
}
