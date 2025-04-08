//
//  DeviceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - DeviceScreen

struct DeviceScreen: View {

    // MARK: Environment
    
    @EnvironmentObject private var environment: DeviceDetailsViewModel.Environment
    @EnvironmentObject private var navigationViewModel: RootNavigationViewModel
    @EnvironmentObject private var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
        
    // MARK: init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view

    var body: some View {
        List {
            if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) {
                if let heartRateServiceViewModel = deviceVM.heartRateServiceViewModel {
                    Section("Heart Monitor") {
                        HeartRateView()
                            .environmentObject(heartRateServiceViewModel)
                    }
                }
                
                if let healthThermometerViewModel = deviceVM.healthThermometerViewModel {
                    Section("Health Thermometer") {
                        HealthThermometerView()
                            .environmentObject(healthThermometerViewModel)
                    }
                }
                
                if let runningViewModel = deviceVM.runningServiceViewModel {
                    Section("Running") {
                        RunningServiceView()
                            .environmentObject(runningViewModel.environment)
                    }
                }
                
                if let cyclingViewModel = deviceVM.cyclingServiceViewModel {
                    Section("Cycling") {
                        CyclingDataView()
                            .environmentObject(cyclingViewModel)
                    }
                }
                
                if let throughputViewModel = deviceVM.throughputViewModel {
                    Section("Throughput") {
                        ThroughputView()
                            .environmentObject(throughputViewModel)
                    }
                }
                
                if let cgmsViewModel = deviceVM.cgmsViewModel {
                    Section("Continuous Glucose Monitoring Service") {
                        CGMSView()
                            .environmentObject(cgmsViewModel)
                    }
                }
            }
            
            Section("Troubleshooting") {
                DisclosureGroup {
                    Text("""
                    If you've recently flashed this Connected Device, the current Services might not match due to caching issues. To solve this, please go back to Settings, Bluetooth, and Turn Off and then On Bluetooth to clear the Cache.
                    
                    Using Control Panel for this will not produce the desired output.
                    """)
                    .foregroundStyle(Color.secondary)
                } label: {
                    Label("Can't find the Services you were looking for?", systemImage: "info.circle")
                }
                .accentColor(.universalAccentColor)
            }
            
            Section("Connection") {
                Button("Disconnect") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        Task { @MainActor in
                            try await connectedDevicesViewModel.disconnectAndRemoveViewModel(device.id)
                            navigationViewModel.selectedCategory = nil
                        }
                    }
                }
                .foregroundStyle(Color.red)
                .centered()
            }
        }
        .taskOnce {
            guard let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) else { return }
            await deviceVM.discoverSupportedServices()
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connectedDevicesViewModel.selectedDevice?.name ?? "Unnamed")
        .inspector(isPresented: $environment.showInspector) {
            InspectorScreen(device)
                .tabItem {
                    Label("Peripheral", systemImage: "terminal")
                }
        }
        .toolbar {
            Button {
                environment.showInspector.toggle()
            } label: {
                Image(systemName: "info")
                    .symbolVariant(.circle)
            }
        }
    }
}
