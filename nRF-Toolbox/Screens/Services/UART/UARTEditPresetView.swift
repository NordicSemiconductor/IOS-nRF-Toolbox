//
//  UARTEditCommandView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTEditCommandView

struct UARTEditPresetView: View {
    
    // MARK: Constant
    
    private static let availableSymbols: [String] = [
        // left arrow, up arrow, right arrow, down arrow, gear
        "chevron.left", "chevron.up", "chevron.right", "chevron.down", "gear",
        // rewind, play, pause, stop, fast forward
        "backward.fill", "play.fill", "pause.fill", "stop.fill", "forward.fill",
        // e.circle, 1, 2, 3, 4
        "e.circle", "1.circle", "2.circle", "3.circle", "4.circle",
        // 5, 6, 7, 8, 9
        "5.circle", "6.circle", "7.circle", "8.circle", "9.circle"
    ]
    
    // MARK: EnvironmentObject
    
    @Environment(UARTViewModel.self) private var viewModel: UARTViewModel
    
    // MARK: State
    
    @State private var editFormat: Format
    @State private var editedPreset: String
    @State private var editEOL: UARTPreset.EndOfLine
    @State private var editSymbol: String
    
    // MARK: Properties
    
    private let command: UARTPreset
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: init
    
    init(_ command: UARTPreset) {
        self.command = command
        self.editFormat = .text
        self.editedPreset = command.toString() ?? ""
        self.editEOL = command.eol
        self.editSymbol = command.symbol
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Command") {
                InlineSegmentedControlPicker(selectedValue: $editFormat,
                                             possibleValues: Format.allCases)
                    .frame(maxWidth: 220)
                
                TextField("UART Command", text: $editedPreset, prompt: Text("Write command here"))
                    .keyboardType(.alphabet)
                    .disableAllAutocorrections()
                    .submitLabel(.done)
            }
            
            Section {
                InlinePicker(title: "End of Line", systemImage: "arrow.down.to.line.compact", selectedValue: $editEOL)
                    .labeledContentStyle(.accentedContent)
            }
            
            Section("Associated Symbol") {
                Grid {
                    ForEach(0..<4) { row in
                        GridRow {
                            ForEach(0..<5) { col in
                                Button(action: {
                                    editSymbol = Self.availableSymbols[row * 5 + col]
                                }, label: {
                                    Image(systemName: Self.availableSymbols[row * 5 + col])
                                        .symbolRenderingMode(.hierarchical)
                                        .font(.system(size: 16))
                                        .frame(size: CGSize(asSquare: 24.0))
                                        .padding(4)
                                })
                                .tint(editSymbol == Self.availableSymbols[row * 5 + col]
                                      ? Color.nordicBlue : Color.secondary)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .centered()
            }
        }
        .navigationTitle("Edit Command #\(command.id + 1)")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    // MARK: API
    
    func save() {
        let presetToSave = UARTPreset(command.id, command: editedPreset, symbol: editSymbol, eol: editEOL)
        viewModel.updateSelectedPresetCommand(presetToSave)
    }
}

// MARK: - Format

fileprivate extension UARTEditPresetView {
    
    enum Format: Int, RawRepresentable, CustomStringConvertible, CaseIterable {
        case text, data
        
        var description: String {
            switch self {
            case .text:
                return "Text"
            case .data:
                return "Data (Hex)"
            }
        }
    }
}
