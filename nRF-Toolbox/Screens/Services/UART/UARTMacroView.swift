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
            .popoverTip(ListOfFavoritesTip())
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 8)
            
//            Button("", systemImage: "info.circle") {
////                Menu("Tip") {
////                    Text("Hello")
////                }
//                print("TODO")
//            }
//            .tint(.primary)
        }
    }
}

struct ListOfFavoritesTip: Tip {
    var title: Text {
        Text("Favorite List")
    }
    var message: Text? {
        Text("Check your favorite list")
    }
    var image: Image? {
        Image(systemName: "star")
    }
}
