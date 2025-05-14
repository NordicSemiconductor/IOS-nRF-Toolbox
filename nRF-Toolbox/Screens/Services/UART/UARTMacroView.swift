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
    
    @State private var editCommandIndex = 0
    @State private var isShowingEditCommand = false
    
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
        HStack(spacing: 16) {
            UARTMacroButtonsView(macro: macro, onTap: { i in
                // TODO: Apply/Execute Current Command
                print("TODO")
            }, onLongPress: { i in
                editCommandIndex = i
                isShowingEditCommand = true
            })
            .background {
                Color.clear
                    .popoverTip(editTip)
                    .id(forceTipUUID)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 8)

            NavigationLink(destination: UARTEditCommandView(macro.commands[editCommandIndex]),
                           isActive: $isShowingEditCommand) {
                EmptyView()
            }
            
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
