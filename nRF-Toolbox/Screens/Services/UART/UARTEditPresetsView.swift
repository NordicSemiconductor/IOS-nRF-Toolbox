//
//  UARTEditPresetsView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTEditPresetsView

struct UARTEditPresetsView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Private Properties
    
    @State private var name: String = ""
    @State private var sequence: [UARTPreset] = [UARTPreset]()

    private let appLog = NordicLog(category: #file)
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
                CancellableTextField("Type preset's set name here", cancelText: name, icon: .text, text: $name)
                    .keyboardType(.alphabet)
                    .submitLabel(.done)
                    .onSubmit {
                        save()
                    }
            }
            
            Section("Presets") {
                UARTPresetsGridView(presets: viewModel.selectedPreset, onTap: { i in
                    viewModel.editCommandIndex = i
                    viewModel.showEditPresetSheet = true
                }, onLongPress: { i in
                    guard viewModel.selectedPreset.commands[i].data != nil else { return }
                    sequence.append(viewModel.selectedPreset.commands[i])
                })
                .aspectRatio(1, contentMode: .fit)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section("Command Sequence") {
                Text ("Tip: Long press command to add it to a sequence.")
                    .foregroundColor(.secondary)
                    .font(Font.caption.bold())
                ForEach(sequence, id: \.self) { command in
                    Text(command.toString() ?? "N/A")
                }
                
                Button("Add Delay") {
                    
                }
                .tint(.universalAccentColor)
                .centered()
            }
            
            Section {
                Button("Save") {
                    viewModel.showEditPresetsSheet = false
                    // onDisappear will trigger a save.
                }
                .tint(.universalAccentColor)
                .centered()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit \(viewModel.selectedPreset.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    viewModel.showEditPresetsSheet = false
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export", systemImage: "square.and.arrow.up") {
                    // TODO: Hopefully soon.
                }
            }
        }
        .doOnce {
            name = viewModel.selectedPreset.name
        }
        .onDisappear {
            save()
        }
    }
    
    // MARK: API
    
    func save() {
        appLog.debug(#function)
        viewModel.savePresets()
    }
}

