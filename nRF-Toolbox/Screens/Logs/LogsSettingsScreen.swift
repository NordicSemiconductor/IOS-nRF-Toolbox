//
//  LogsSettingsScreen.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 08/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import SwiftUI
import iOS_Common_Libraries

// MARK: - LogsScreen

struct LogsSettingsScreen: View {
    
    @Environment(LogsSettingsViewModel.self) var viewModel: LogsSettingsViewModel
    @Environment(AppViewModel.self) var appViewModel: AppViewModel
    @State private var isDeleteDialogShown = false

    var body: some View {
        @Bindable var appViewModel = appViewModel
        List {
            Section("Configuration") {
                Toggle(isOn: $appViewModel.logsSettings.isEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .frame(width: 24)
                            .foregroundColor(.universalAccentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Logs collection")
                                .font(.body)

                            Text("Automatically save device logs.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.universalAccentColor)
            }
            .tint(.universalAccentColor)
            
            Section("Warning") {
                Label("Disk space warning", systemImage: "exclamationmark.triangle.fill")
                    .setAccent(.black)
                    .tint(.black)
                    .foregroundStyle(.black)
                Text("Logging can consume significant disk space over time and may impact performance. Logs will be automatically cleaned once they reach 100 000 records. It is recommended to clean the logs before performing any import task to ensure there is enough space available for new log entries.")
                    .font(.footnote)
                    .setAccent(.black)
                    .tint(.black)
                    .foregroundStyle(.black)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.nordicSun)
            
            let logsMeta = viewModel.logsMeta
            Section("Statistics") {
                VStack {
                    HStack(alignment: .bottom) {
                        Text("Number of records:").font(.caption)
                        Spacer()
                        let currentSize = (logsMeta != nil) ? "\(logsMeta!.count)" : "loading"
                        Text(currentSize)
                    }
                    ProgressView(value: Double(logsMeta?.count ?? 0), total: Double(logsMeta?.maxCount ?? 100))
                        .progressViewStyle(LinearProgressViewStyle(tint: .universalAccentColor))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    HStack {
                        Text("Used: \(logsMeta?.percentageUsed ?? 0)%").font(.caption)
                        Spacer()
                        Text("Free \(logsMeta?.percentageLeft ?? 100)%").font(.footnote)
                    }
                }
            }
            .setAccent(.universalAccentColor)
            .tint(.primarylabel)
            
            Section("Actions") {
                ShareLink(
                    item: LogsTransfarable(),
                    preview: SharePreview(
                        "nRF Toolbox Logs",
                        image: Image("AppIconPreview")
                    )) {
                        Label("Share logs", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.logs == nil)
                Button(action: {
                    isDeleteDialogShown = true
                }, label: {
                    Label("Clear All Logs", systemImage: "trash")
                })
                .tint(.nordicRed)
                .setAccent(.nordicRed)
            }
            .setAccent(.universalAccentColor)
            .tint(.primarylabel)
        }
        .alert("Clear All Logs?", isPresented: $isDeleteDialogShown) {
            Button("Delete", role: .destructive) {
                appViewModel.clearLogs()
                isDeleteDialogShown = false
            }
            Button("Cancel", role: .cancel) {
                isDeleteDialogShown = false
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
