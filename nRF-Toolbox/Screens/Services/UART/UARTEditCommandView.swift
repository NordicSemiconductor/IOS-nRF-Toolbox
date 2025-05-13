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
        // info.circle, 1, 2, 3, 4
        "info.circle", "1.circle", "2.circle", "3.circle", "4.circle",
        // 5, 6, 7, 8, 9
        "5.circle", "6.circle", "7.circle", "8.circle", "9.circle"
    ]
    
    // MARK: State
    
    @State private var editCommand: String
    @State private var editEOL: UARTMacroCommand.EndOfLine
    
    // MARK: Properties
    
    private let command: UARTMacroCommand
    
    // MARK: init
    
    init(_ command: UARTMacroCommand) {
        self.command = command
        self.editCommand = command.command
        self.editEOL = command.eol
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Command") {
                TextField("", text: $editCommand)
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
                                    //
                                }, label: {
                                    Image(systemName: Self.availableSymbols[row * 5 + col])
                                        .resizable()
                                        .frame(size: CGSize(asSquare: 22.0))
                                })
                                .tint(Color.nordicBlue)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

            }
        }
        .navigationTitle("Edit Command #\(command.id + 1)")
    }
}
