//
//  UARTEditMacroView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - UARTEditMacroView

struct UARTEditMacroView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
                //                TextField("UART Command", text: $editCommand, prompt: Text("Write command here"))
                //                    .keyboardType(.alphabet)
                //                    .disableAllAutocorrections()
                //                    .submitLabel(.done)
            }
            
            Section("Commands") {
                
            }
            
            Section("Command Sequence") {
                Button("Add Delay") {
                    
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit \(viewModel.selectedMacro.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Hi") {
                print("Hi")
            }
            .foregroundStyle(Color.primarylabel)
            
            Button("Export", systemImage: "square.and.arrow.up") {
                // TODO: Hopefully soon.
            }
            .tint(Color.white)
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

