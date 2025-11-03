//
//  UARTPresetsMainView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 8/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTPresetsMainView

struct UARTPresetsMainView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Properties
    
    @State private var showNewPresetsAlert: Bool = false
    @State private var newPresetsName: String = ""
    
    // MARK: view
    
    var body: some View {
        DisclosureGroup {
            HStack {
                InlinePicker(title: "", systemImage: "command.square", selectedValue: $viewModel.selectedPreset,
                             possibleValues: viewModel.presets)
                    .labeledContentStyle(.accentedContent)
                
                Button {
                    viewModel.deleteSelectedPresets()
                } label: {
                    Image(systemName: "trash")
                        .frame(size: Constant.ButtonSize)
                }
                .disabled(viewModel.selectedPreset == .none)
                .buttonStyle(.bordered)
                .foregroundStyle(Color.nordicRed)
                
                Button {
                    newPresetsName = ""
                    showNewPresetsAlert = true
                } label: {
                    Image(systemName: "plus")
                        .frame(size: Constant.ButtonSize)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(Color.universalAccentColor)
                
                Button {
                    // TODO: Import
                    print("TODO: Import")
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .frame(size: Constant.ButtonSize)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(Color.primary)
            }
            
            UARTPresetControlView(viewModel.selectedPreset)
                .disabled(viewModel.selectedPreset == .none)
        } label: {
            Text("Presets")
                .font(.title2.bold())
        }
        .tint(.universalAccentColor)
        .alert("New Presets", isPresented: $showNewPresetsAlert) {
            TextField("Type Name Here", text: $newPresetsName)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.newPresets(named: newPresetsName)
                    newPresetsName = ""
                    showNewPresetsAlert = false
                }
            
            Button("Cancel", role: .cancel) {
                showNewPresetsAlert = false
            }
            
            Button("Add") {
                viewModel.newPresets(named: newPresetsName)
                newPresetsName = ""
                showNewPresetsAlert = false
            }
        }
    }
}

// MARK: Constant

extension Constant {
    
    // MARK: Size
    
    static let ButtonSize = CGSize(asSquare: 22.0)
}
