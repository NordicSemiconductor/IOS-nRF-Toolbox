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
                viewModel.runCommand(macro.commands[i])
            }, onLongPress: { i in
                // No-op.
            })
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 8)

            VStack(spacing: 16) {
                Button("", systemImage: "gear") {
                    isShowingEditCommand = true
                }
                .tint(.primary)
                .sheet(isPresented: $isShowingEditCommand) {
                    NavigationView {
                        UARTEditMacroView(macro)
                            .navigationBarItems(trailing: HStack {
                                Button("Hello") {
                                    
                                }
                            })
                    }
                    .setupNavBarBackground(with: Assets.navBar.color)
                    
                    
//                    .navigationBarItems(trailing: HStack {
//                        Button(action: { ... }) {
//                            Text("Done")
//                        })
//                    })
//                    .toolbar {
//                        Button("Export", systemImage: "square.and.arrow.up") {
//                            // TODO: Hopefully soon.
//                        }
//                        .foregroundStyle(Color.white)
//                    }
                    .environmentObject(viewModel)
                }
                
                Button("", systemImage: "play.fill") {
                    print("PLAY")
                }
                .tint(.nordicBlue)
            }
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
