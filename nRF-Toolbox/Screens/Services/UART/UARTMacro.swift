//
//  UARTMacro.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 7/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - UARTMacro

struct UARTMacro: Identifiable, Hashable, Equatable, CustomStringConvertible {
    
    // MARK: Unselected
    
    static let none = UARTMacro(name: "--")
    
    // MARK: Properties
    
    let name: String
    
    var id: String { name }
    var description: String { name }
}
