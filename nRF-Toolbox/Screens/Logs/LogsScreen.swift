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

private enum Tabs {
    case settings, preview
}

// MARK: - LogsScreen

struct LogsScreen: View {
    
    @StateObject var viewModel = LogsPreviewViewModel()
    
    @Query(sort: \LogDb.timestamp) var logs: [LogDb]
    @State private var selectedTab: Tabs = .settings
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Settings", systemImage: "gear", value: Tabs.settings) {
                LogsSettingsScreen()
            }
            
            Tab("Preview", systemImage: "list.bullet.clipboard", value: Tabs.preview) {
                LogsPreviewScreen()
            }
        }
        .navigationTitle("Logs")
        .applyTabBarMinimazeBehaviorIfAvailable()
        .tint(.universalAccentColor)
        .environmentObject(viewModel)
        .onChange(of: logs, initial: true) {
            viewModel.updateModel(logs: logs)
        }
    }
}

private extension View {
    @ViewBuilder
    func applyTabBarMinimazeBehaviorIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
