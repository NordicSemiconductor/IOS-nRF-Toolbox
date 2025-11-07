//
//  UARTEditPresetsView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import AEXML

// MARK: - UARTSequenceItem

enum UARTSequenceItem : Hashable {
    case delay(Int)
    case command(UARTPreset)
}

struct SequenceItemView : View {
    
    let item: UARTSequenceItem
    @State var value: Float
    
    init(item: UARTSequenceItem) {
        self.item = item
        if case let .delay(delay) = item {
            self.value = Float(delay)
        } else {
            self.value = 0
        }
    }
    
    var body: some View {
        switch item {
        case .delay:
            Slider(value: $value, in: 0...30, step: 1) {
                EmptyView()
            } minimumValueLabel: {
                Text("0 ms")
            } maximumValueLabel: {
                Text("200 ms")
            }
            .onChange(of: value) {
                self.value = value
            }
        case .command(let preset):
            Text(preset.toString() ?? "N/A")
        }
    }
}

// MARK: - UARTEditPresetsView

struct UARTEditPresetsView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Private Properties
  
    @State private var name: String = ""
    @State private var sequence: [UARTSequenceItem] = [UARTSequenceItem]()
    
    private let appLog = NordicLog(category: #file)
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
                CancellableTextField("Type preset's set name here", cancelText: name, icon: .text, text: $name)
                    .keyboardType(.alphabet)
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.updateSelectedPresetsName(name)
                    }
            }
            
            Section("Presets") {
                UARTPresetsGridView(presets: viewModel.editedPresets, onTap: { i in
                    viewModel.editCommandIndex = i
                    viewModel.showEditPresetSheet = true
                }, onLongPress: { i in
                    guard viewModel.selectedPresets.commands[i].data != nil else { return }
                    sequence.append(.command(viewModel.selectedPresets.commands[i]))
                })
                .aspectRatio(1, contentMode: .fit)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section("Command Sequence") {
                Text ("Tip: Long press command to add it to a sequence.")
                    .foregroundColor(.secondary)
                    .font(Font.caption.bold())
                ForEach(Array(sequence.enumerated()), id: \.offset) { index, command in
                    SequenceItemView(item: command)
                }
                
                Button("Add Delay") {
                    sequence.append(.delay(1))
                }
                .tint(.universalAccentColor)
                .centered()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit \(viewModel.selectedPresets.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    viewModel.showEditPresetsSheet = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    viewModel.updateSelectedPresetsName(name)
                    viewModel.savePresets()
                }.disabled(viewModel.pendingChanges)
            }
        }
        .doOnce {
            viewModel.startEdit()
            name = viewModel.editedPresets.name
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { viewModel.showAlert = false }
        }
    }
}
