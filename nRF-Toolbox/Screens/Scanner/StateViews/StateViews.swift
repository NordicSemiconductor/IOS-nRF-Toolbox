//
//  StateViews.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetooth

// MARK: - StateViews

struct StateViews {
    
    // MARK: Unsupported
    
    struct Unsupported: View {
        
        var body: some View {
            NoContentView(
                title: "Bluetooth is Unavailable",
                systemImage: "hand.thumbsdown",
                description: "It looks like your device doesn't support bluetooth"
            )
            .padding()
        }
    }
    
    // MARK: Unauthorized
    
    struct Unauthorized: View {
        
        var body: some View {
            VStack {
                NoContentView(
                    title: "No Permission Granted",
                    systemImage: "xmark.seal",
                    description: "Bluetooth is not authorized. Open settings and give access the application to use Bluetooth."
                )
                
                Button("Open Settings") {
                    guard let settingsURL = URL(string: "App-Prefs:root=General") else { return }
                    UIApplication.shared.open(settingsURL) { _ in
                        // No-op.
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    // MARK: Disabled
    
    struct Disabled: View {
        
        var body: some View {
            VStack {
                NoContentView(
                    title: "Bluetooth is Turned Off",
                    systemImage: "gear",
                    description: "It looks like Bluetooth is turnd off. You can turn it on in Settings"
                )
                Button("Open Settings") {
                    // TODO: Open Settings
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    // MARK: EmptyResults
    
    struct EmptyResults: View {
        
        // MARK: Environment
        
        @EnvironmentObject private var viewModel: PeripheralScannerScreen.PeripheralScannerViewModel
        
        // MARK: view
        
        var body: some View {
            List {
                ScanResultItem(
                    name: "Two Words",
                    rssi: -90,
                    services: [.heartRate, .runningSpeedAndCadence]
                )
                ScanResultItem(
                    name: "Three Words Name",
                    rssi: -50,
                    services: []
                )
                ScanResultItem(
                    name: "Two Words",
                    rssi: -60,
                    services: [.runningSpeedAndCadence]
                )
            }
            .listStyle(.insetGrouped)
            .redacted(reason: .placeholder)
        }
    }
}
