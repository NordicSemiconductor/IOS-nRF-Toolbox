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
    
    @Binding var showNewMacroAlert: Bool
    @Binding var newMacroName: String
    
    // MARK: view
    
    var body: some View {
        HStack {
            InlinePicker(title: "Selected", selectedValue: $viewModel.selectedMacro,
                         possibleValues: viewModel.macros, onChange: { newValue in
                viewModel.selectedMacro = newValue
            })
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
        
        if viewModel.selectedMacro != .none {
            viewModel.selectedMacro
        }
    }
}
