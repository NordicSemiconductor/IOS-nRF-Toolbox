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
                        viewModel.savePresets()
                    }
            }
            
            Section("Presets") {
                UARTPresetsGridView(presets: viewModel.selectedPresets, onTap: { i in
                    viewModel.editCommandIndex = i
                    viewModel.showEditPresetSheet = true
                }, onLongPress: { i in
                    guard viewModel.selectedPresets.commands[i].data != nil else { return }
                    sequence.append(viewModel.selectedPresets.commands[i])
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
                Button("Dismiss", systemImage: "checkmark") {
                    viewModel.savePresetsToFile()
                }.disabled(viewModel.pendingChanges)
            }
        }
        .onAppear {
            viewModel.savePresetsToFile(notifyUser: false)
        }
        .doOnce {
            name = viewModel.selectedPresets.name
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { viewModel.showAlert = false }
        }
    }
}
