//
//  UARTEditCommandView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

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
    
    // MARK: Properties
    
    private let command: UARTMacroCommand
    
    // MARK: init
    
    init(_ command: UARTMacroCommand) {
        self.command = command
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section("") {
                Text("TODO")
            }
        }
        .navigationTitle("Edit Command #\(command.id + 1)")
    }
}
