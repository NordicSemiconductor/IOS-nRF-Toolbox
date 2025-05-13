//
//  UARTMacroView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - UARTMacroView

struct UARTMacroView: View {
    
    // MARK: Constant
    
    // End of line: LF | CR | CR+LF
    
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
    
    // MARK: Properties
    
    @State private var showEditCommandAlert: Bool = false
    
    @State private var editCommandID: Int = 0
    @State private var editCommand: String = ""
    
    private let macro: UARTMacro
    
    // MARK: Init
    
    init(_ macro: UARTMacro) {
        self.macro = macro
    }
    
    // MARK: view
    
    var body: some View {
        Grid(alignment: .center, horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(0..<3) { col in
                        Button(action: {
                            editCommandID = row * 3 + col
                            editCommand = ""
                            showEditCommandAlert = true
                        }, label: {
                            Image(systemName: macro.commands[row * 3 + col].symbol)
                                .resizable()
                                .frame(size: CGSize(asSquare: 40.0))
                        })
                        .tint(macro.inEditMode ? Color.red : Color.nordicBlue)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, 8)
        .alert("Edit Command", isPresented: $showEditCommandAlert) {
            TextField("Type Command Here", text: $editCommand)
                .submitLabel(.done)
                .onSubmit {
                    showEditCommandAlert = false
                }
            
//            Divider()
//            
//            Text("End-of-Line")
//            
//            Divider()
//            
//            Text("Associated Symbol")
            
            Grid {
                ForEach(0..<4) { row in
                    GridRow {
                        ForEach(0..<5) { col in
                            Button(action: {
                                //
                            }, label: {
                                Image(systemName: Self.availableSymbols[row * 3 + col])
                                    .resizable()
                                    .frame(size: CGSize(asSquare: 22.0))
                            })
                            .tint(Color.nordicBlue)
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
//            Button("Cancel", role: .cancel) {
//                showEditCommandAlert = false
//            }
//            
//            Button("Save") {
//                showEditCommandAlert = false
//            }
        }
    }
}
