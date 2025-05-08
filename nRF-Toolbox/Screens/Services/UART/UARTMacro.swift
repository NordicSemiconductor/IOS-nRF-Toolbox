//
//  UARTMacro.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 7/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTMacro

struct UARTMacro: Identifiable, Hashable, Equatable, CustomStringConvertible {
    
    // MARK: Unselected
    
    static let none = UARTMacro("--")
    
    // MARK: Constants
    
    static let numberOfCommands = 9
    static private let threeColumns = [
        GridItem(.fixed(120), spacing: 0),
        
        GridItem(.fixed(120), spacing: 0),
        
        GridItem(.fixed(120), spacing: 0)
    ]
    
    // MARK: Properties
    
    let name: String
    let inEditMode: Bool
    let commands: [UARTMacroCommand]
    
    var id: String { name }
    var description: String { name }
    
    // MARK: Init
    
    init(_ name: String, editMode: Bool = false) {
        self.name = name.isEmpty ? "Unnamed Macro" : name
        self.inEditMode = editMode
        var emptyCommands = [UARTMacroCommand]()
        emptyCommands.reserveCapacity(Self.numberOfCommands)
        for i in 0..<Self.numberOfCommands {
            emptyCommands.append(UARTMacroCommand(i))
        }
        self.commands = emptyCommands
    }
}

// MARK: - UARTMacroCommand

struct UARTMacroCommand: Identifiable, Hashable, Equatable {
    
    let id: Int
    let command: String
    let symbol: String
    
    init(_ id: Int, command: String = "", symbol: String = "e.circle") {
        self.id = id
        self.command = command
        self.symbol = symbol
    }
}

// MARK: - View

extension UARTMacro: View {
    
    var body: some View {
        LazyVGrid(columns: UARTMacro.threeColumns, spacing: 20) {
            ForEach(commands) { command in
                Button(action: {
                    // TODO
                }, label: {
                    Image(systemName: command.symbol)
                        .resizable()
                        .frame(size: CGSize(width: 30.0, height: 30.0))
                })
                .tint(inEditMode ? Color.red : Color.nordicBlue)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
}
