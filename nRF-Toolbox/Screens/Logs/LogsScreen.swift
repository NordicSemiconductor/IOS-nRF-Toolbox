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
    
    @StateObject var viewModel = LogsSettingsViewModel(container: SwiftDataContextManager.shared.container!)
    
    @State private var selectedTab: Tabs = .settings
    
    @State private var searchText: String = ""
    @State private var selectedLogLevel: LogLevel = .debug

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Settings", systemImage: "gear", value: Tabs.settings) {
                LogsSettingsScreen()
                    .environmentObject(viewModel)
            }
            
            Tab("Preview", systemImage: "list.bullet.clipboard", value: Tabs.preview) {
                LogsPreviewScreen()
                    .environmentObject(viewModel)
            }
        }
        .navigationTitle("Logs")
        .applyTabBarMinimazeBehaviorIfAvailable()
        .tint(.universalAccentColor)
        .onDisappear {
            viewModel.stop()
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
