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
                        NavigationLink {
                            UARTEditCommandView(macro.commands[row * 3 + col])
                        } label: {
                            Image(systemName: macro.commands[row * 3 + col].symbol)
                                .resizable()
                                .frame(size: CGSize(asSquare: 40.0))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, 8)
    }
}
