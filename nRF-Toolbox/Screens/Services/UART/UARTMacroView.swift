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
            
            Divider()
            
            Text("Associated Symbol")
            
            Divider()
            
            Button("Cancel", role: .cancel) {
                showEditCommandAlert = false
            }
            
            Button("Save") {
                
                showEditCommandAlert = false
            }
        }
    }
}
