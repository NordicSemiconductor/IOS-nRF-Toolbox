//
//  BlinkingCursorView.swift
//  iOSCommonLibraries
//
//  Created by Dinesh Harjani on 17/10/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - BlinkingCursorView

public struct BlinkingCursorView: View {
    
    // MARK: init
    
    public init() {}
    
    // MARK: view
    
    public var body: some View {
        Text("█")
            .foregroundColor(Color.universalAccentColor)
            .glow()
            .blink()
    }
}
