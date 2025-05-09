//
//  UARTMacroSelectionView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 8/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTMacroSelectionView

struct UARTMacroSelectionView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Properties
    
    @State private var showNewMacroAlert: Bool = false
    @State private var newMacroName: String = ""
    
    // MARK: view
    
    var body: some View {
        DisclosureGroup {
            HStack {
                InlinePicker(title: "Selected", selectedValue: $viewModel.selectedMacro,
                             possibleValues: viewModel.macros)
                    .labeledContentStyle(.accentedContent)
                
                Button {
                    viewModel.deleteSelectedMacro()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.selectedMacro == .none)
                .buttonStyle(.bordered)
                .foregroundStyle(Color.nordicRed)
                
                Button {
                    newMacroName = ""
                    showNewMacroAlert = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .foregroundStyle(Color.universalAccentColor)
            }
            
            viewModel.selectedMacro
                .disabled(viewModel.selectedMacro == .none)
        } label: {
            Text("Macros")
                .font(.title2.bold())
        }
        .tint(.universalAccentColor)
        .alert("New Macro", isPresented: $showNewMacroAlert) {
            TextField("Type Name Here", text: $newMacroName)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.newMacro(named: newMacroName)
                    newMacroName = ""
                    showNewMacroAlert = false
                }
            
            Button("Cancel", role: .cancel) {
                showNewMacroAlert = false
            }
            
            Button("Add") {
                viewModel.newMacro(named: newMacroName)
                newMacroName = ""
                showNewMacroAlert = false
            }
        }
    }
}
