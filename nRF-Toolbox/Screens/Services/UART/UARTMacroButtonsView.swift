//
//  UARTMacroButtonsView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - UARTMacroButtonsView

struct UARTMacroButtonsView: View {
    
    // MARK: Properties
    
    let macro: UARTMacro
    let onTap: (Int) -> Void
    let onLongPress: (Int) -> Void
    
    // MARK: view
    
    var body: some View {
        Grid(alignment: .center, horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(0..<3) { col in
                        Button {
                            // No-op.
                            // Keep as a no-op so both long press and tap work.
                        } label: {
                            Image(systemName: macro.commands[row * 3 + col].symbol)
                                .resizable()
                                .frame(size: CGSize(asSquare: 40.0))
                        }
                        .simultaneousGesture(LongPressGesture().onEnded { _ in
                            onLongPress(row * 3 + col)
                        })
                        .simultaneousGesture(TapGesture().onEnded {
                            onTap(row * 3 + col)
                        })
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}
