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
    
    @EnvironmentObject var settingsViewModel: LogsSettingsViewModel
    @State private var isDeleteDialogShown = false
    
    @Query(sort: \LogDb.timestamp, order: .forward) var logs: [LogDb]
    @State var logsMeta = LogsMeta()
    
    private var sharedItem: Logs {
        Logs(values: logs)
    }

    var body: some View {
        List {
            Section("Configuration") {
                Toggle(isOn: $settingsViewModel.logsSettings.isEnabled) {
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
            
            Section("Statistics") {
                VStack {
                    HStack(alignment: .bottom) {
                        Text("Current size:").font(.caption)
                        Spacer()
                        Text("\(logsMeta.size) MB")
                    }
                    ProgressView(value: Double(logsMeta.size), total: Double(logsMeta.maxSize))
                        .progressViewStyle(LinearProgressViewStyle(tint: .universalAccentColor))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    HStack {
                        Text("Used: \(logsMeta.percentageUsed)%").font(.caption)
                        Spacer()
                        Text("Free \(logsMeta.percentageLeft)%").font(.footnote)
                    }
                }
            }
            .setAccent(.universalAccentColor)
            .tint(.primarylabel)
            
            Section("Actions") {
                ShareLink(
                    item: sharedItem,
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
        .onAppear {
            logsMeta = getSwiftDataStoreSize() ?? LogsMeta()
        }
        .alert("Clear All Logs?", isPresented: $isDeleteDialogShown) {
            Button("Delete", role: .destructive) {
                settingsViewModel.clearLogs()
                isDeleteDialogShown = false
            }
            Button("Cancel", role: .cancel) {
                isDeleteDialogShown = false
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    func getSwiftDataStoreSize() -> LogsMeta? {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("default.store") else {
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[FileAttributeKey.size] as? UInt64 {
                let megabytes = Double(fileSize) / (1024 * 1024)
                return LogsMeta(size: megabytes)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return nil
    }
}
