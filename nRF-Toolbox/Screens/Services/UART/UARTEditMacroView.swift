//
//  UARTEditMacroView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTEditMacroView

struct UARTEditMacroView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Private Properties
    
    @State private var name: String = ""
    @State private var sequence: [UARTMacroCommand] = [UARTMacroCommand]()
    
    private let appLog = NordicLog(category: #file)
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
                CancellableTextField("Type macro name here", cancelText: name, icon: .text, text: $name)
                    .keyboardType(.alphabet)
                    .submitLabel(.done)
                    .onSubmit {
                        save()
                    }
            }
            
            Section("Commands") {
                UARTMacroButtonsView(macro: viewModel.selectedMacro, onTap: { i in
                    guard viewModel.selectedMacro.commands[i].data != nil else { return }
                    sequence.append(viewModel.selectedMacro.commands[i])
                }, onLongPress: { i in
                    viewModel.editCommandIndex = i
                    viewModel.showEditCommandSheet = true
                })
                .aspectRatio(1, contentMode: .fit)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section("Command Sequence") {
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
                    viewModel.showEditMacroSheet = false
                    // onDisappear will trigger a save.
                }
                .tint(.universalAccentColor)
                .centered()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit \(viewModel.selectedMacro.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    viewModel.showEditMacroSheet = false
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export", systemImage: "square.and.arrow.up") {
                    // TODO: Hopefully soon.
                }
            }
        }
        .doOnce {
            name = viewModel.selectedMacro.name
        }
        .onDisappear {
            save()
        }
    }
    
    // MARK: API
    
    func save() {
        appLog.debug(#function)
        viewModel.saveMacros()
    }
}

