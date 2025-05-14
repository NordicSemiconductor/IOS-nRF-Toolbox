//
//  UARTMacroView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import TipKit

// MARK: - UARTMacroView

struct UARTMacroView: View {
    
    // MARK: Properties
    
    private let macro: UARTMacro
    
    @State private var forceTipUUID = UUID()
    private var editTip: EditCommandsTip {
        EditCommandsTip(id: forceTipUUID.uuidString)
    }
    
    // MARK: Init
    
    init(_ macro: UARTMacro) {
        self.macro = macro
        try? Tips.configure()
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            Grid(alignment: .center, horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(0..<3) { row in
                    GridRow {
                        ForEach(0..<3) { col in
                            Button {
                                
                            } label: {
                                Image(systemName: macro.commands[row * 3 + col].symbol)
                                    .resizable()
                                    .frame(size: CGSize(asSquare: 40.0))
                            }
                            .buttonStyle(.borderedProminent)
                            
//                            NavigationLink {
//                                UARTEditCommandView(macro.commands[row * 3 + col])
//                            } label: {
//                                Image(systemName: macro.commands[row * 3 + col].symbol)
//                                    .resizable()
//                                    .frame(size: CGSize(asSquare: 40.0))
//                            }
//                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .background {
                Color.clear
                    .popoverTip(editTip)
                    .id(forceTipUUID)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 8)
            
            Button("", systemImage: "info.circle") {
                forceTipUUID = UUID()
                EditCommandsTip.isVisible[editTip.id] = true
            }
            .tint(.primary)
        }
    }
}

// MARK: Edit Command Tip

struct EditCommandsTip: Tip {
    
    // MARK: Properties
    
    let id: String
    
    // MARK: UI
    
    var title: Text {
        Text("Edit Macro Command(s)")
            .foregroundStyle(Color.nordicBlue)
    }
    
    var message: Text? {
        Text("Long-press to Edit")
    }
    
    var image: Image? {
        Image(systemName: "e.circle")
    }
    
    // MARK: Logic
    
    @Parameter
    static var isVisible: [String: Bool] = [:]
    
    var rules: [Rule] {
        #Rule(Self.$isVisible) { tip in
            tip[id] == true
        }
    }
}
