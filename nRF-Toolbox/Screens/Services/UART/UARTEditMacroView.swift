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
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
                TextField("Name", text: $name, prompt: Text("Type macro name here"))
                    .keyboardType(.alphabet)
                    .disableAllAutocorrections()
                    .submitLabel(.done)
            }
            
            Section("Commands") {
                
            }
            
            Section("Command Sequence") {
                Button("Add Delay") {
                    
                }
                .tint(.universalAccentColor)
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
                .tint(Color.white)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export", systemImage: "square.and.arrow.up") {
                    // TODO: Hopefully soon.
                }
                .tint(Color.white)
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
        // TODO
    }
}

