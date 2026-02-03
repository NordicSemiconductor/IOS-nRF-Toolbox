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

enum LogsTab {
    case settings, preview
}

// MARK: - LogsScreen

struct LogsScreen: View {
    
    @State private var viewModel: LogsSettingsViewModel?
    
    @State private var selectedTab: LogsTab
    
    @State private var searchText: String = ""
    @State private var selectedLogLevel: LogLevel = .debug
    
    init(tab: LogsTab) {
        selectedTab = tab
    }

    var body: some View {
        ViewModelContainer(createVM: { LogsSettingsViewModel(container: SwiftDataContextManager.shared.container!) }) { viewModel in
            TabView(selection: $selectedTab) {
                Tab("Settings", systemImage: "gear", value: LogsTab.settings) {
                    LogsSettingsScreen()
                        .environment(viewModel)
                }
                
                Tab("Preview", systemImage: "list.bullet.clipboard", value: LogsTab.preview) {
                    LogsPreviewScreen()
                        .environment(viewModel)
                }
            }
            .applyTabBarMinimazeBehaviorIfAvailable()
            .tint(.universalAccentColor)
        }
        .navigationTitle("Logs")
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
