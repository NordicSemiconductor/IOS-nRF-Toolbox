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

struct UARTEditCommandView: View {
    
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
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: State
    
    @State private var editCommand: String
    @State private var editEOL: UARTMacroCommand.EndOfLine
    @State private var editSymbol: String
    
    // MARK: Properties
    
    private let command: UARTMacroCommand
    
    // MARK: init
    
    init(_ command: UARTMacroCommand) {
        self.command = command
        self.editCommand = command.command
        self.editEOL = command.eol
        self.editSymbol = command.symbol
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Command") {
                TextField("UART Command", text: $editCommand, prompt: Text("Write command here"))
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
                                        .resizable()
                                        .frame(size: CGSize(asSquare: 22.0))
                                })
                                .tint(editSymbol == Self.availableSymbols[row * 5 + col]
                                      ? Color.nordicBlue : Color.secondary)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            save()
        }
        .navigationTitle("Edit Command #\(command.id + 1)")
        .toolbar {
            Button("Export", systemImage: "square.and.arrow.up") {
                // TODO: Hopefully soon.
            }
        }
    }
    
    // MARK: API
    
    func save() {
        let saveCommand = UARTMacroCommand(command.id, command: editCommand,
                                           symbol: editSymbol, eol: editEOL)
        viewModel.updateSelectedMacroCommand(saveCommand)
    }
}
