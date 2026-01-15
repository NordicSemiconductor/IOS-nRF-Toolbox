//
//  LogsScreen.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 08/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import SwiftUI
import iOS_Common_Libraries

// MARK: - LogsScreen

struct LogsScreen: View {
    
    var body: some View {
        TabView {
            Tab("Settings", systemImage: "tray.and.arrow.down.fill") {
                LogsSettingsScreen()
            }
            
            Tab("Logs", systemImage: "tray.and.arrow.up.fill") {
                LogsPreviewScreen()
            }
            Tab(role: .search) {
                LogsPreviewScreen()
            }
        }
        .applyTabBarMinimazeBehaviorIfAvailable()
        .tint(.universalAccentColor)
        
    }
}

extension View {
    @ViewBuilder
    func applyTabBarMinimazeBehaviorIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
