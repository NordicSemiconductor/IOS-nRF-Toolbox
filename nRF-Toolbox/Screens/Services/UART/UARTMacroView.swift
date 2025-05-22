//
//  UARTMacroView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import TipKit

// MARK: - UARTMacroView

struct UARTMacroView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Properties
    
    private let macro: UARTMacro
    
    // MARK: Init
    
    init(_ macro: UARTMacro) {
        self.macro = macro
    }
    
    // MARK: view
    
    var body: some View {
        HStack(spacing: 16) {
            UARTMacroButtonsView(macro: macro, onTap: { i in
                viewModel.runCommand(macro.commands[i])
            }, onLongPress: { i in
                // No-op.
            })
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 8)

            VStack(spacing: 16) {
                Button("", systemImage: "gear") {
                    viewModel.showEditMacroSheet = true
                }
                .tint(.primary)
                
                Button("", systemImage: "play.fill") {
                    print("PLAY")
                }
                .tint(.nordicBlue)
            }
        }
    }
}
