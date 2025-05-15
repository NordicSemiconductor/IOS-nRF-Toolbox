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
    
    // MARK: Properties
    
    private let macro: UARTMacro
    
    // MARK: init
    
    init(_ macro: UARTMacro) {
        self.macro = macro
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
//                TextField("UART Command", text: $editCommand, prompt: Text("Write command here"))
//                    .keyboardType(.alphabet)
//                    .disableAllAutocorrections()
//                    .submitLabel(.done)
            }
        }
        .onDisappear {
            save()
        }
        .navigationTitle("Edit \(macro.name)")
        .toolbar {
            Button("Export", systemImage: "square.and.arrow.up") {
                // TODO: Hopefully soon.
            }
        }
    }
    
    // MARK: API
    
    func save() {
        
    }
}

