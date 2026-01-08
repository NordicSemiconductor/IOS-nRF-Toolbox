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
    
    @Query(sort: \LogDb.timestamp) var logs: [LogDb]
    
    @EnvironmentObject var viewModel: ConnectedDevicesViewModel
    @State private var isDeleteDialogShown = false
    
    var body: some View {
        List {
            Section("Configuration") {
                Toggle(isOn: $viewModel.logsSettings.isEnabled) {
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
                Text("Logging can consume significant disk space over time. Clear logs to free up storage.")
                    .font(.footnote)
                    .setAccent(.black)
                    .tint(.black)
                    .foregroundStyle(.black)
                    
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.nordicSun)
            
            Section("Actions") {
                ShareLink(
                    item: Logs(values: logs.map { $0.value }),
                    preview: SharePreview(
                        "nRF Toolbox Logs",
                        image: Image("AppIconPreview")
                    )) {
                        Label("Share logs", systemImage: "square.and.arrow.up")
                    }
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
        .navigationTitle("Logs settings")
        .alert("Clear All Logs?", isPresented: $isDeleteDialogShown) {
            Button("Delete", role: .destructive) {
                viewModel.clearLogs()
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
