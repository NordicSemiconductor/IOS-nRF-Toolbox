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
                
                deviceVM.supportedServiceViews()
                
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
                
                if let bpsViewModel = deviceVM.bloodPressureViewModel {
                    Section("Blood Pressure") {
                        BloodPressureView()
                            .environmentObject(bpsViewModel)
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
                
                if let uartViewModel = deviceVM.uartViewModel {
                    Section("UART") {
                        UARTView()
                            .environmentObject(uartViewModel)
                    }
                }
            }
            
            Section("Device Information") {
                Button("Open Inspector", systemImage: "info.circle") {
                    environment.showInspector.toggle()
                }
                .foregroundStyle(Color.universalAccentColor)
                .centered()
            }
            
            Section("Troubleshooting") {
                DisclosureGroup {
                    Text("Turn off and on Bluetooth from Settings (not Control Center) to clear the cache.")
                        .foregroundStyle(Color.secondary)
                } label: {
                    Label("Can't find your service?", systemImage: "exclamationmark.magnifyingglass")
                }
                .accentColor(.universalAccentColor)
            }
            
            Section("Connection") {
                switch device.status {
                case .userInitiatedDisconnection:
                    ProgressView()
                case .error(let error):
                    Label(error.localizedDescription, systemImage: "exclamationmark.circle")
                        .foregroundStyle(Color.nordicRed)
                case .connected:
                    Button("Disconnect") {
                        disconnect()
                    }
                    .foregroundStyle(Color.red)
                    .centered()
                }
            }
        }
        .taskOnce {
            await serviceDiscovery()
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connectedDevicesViewModel.selectedDevice?.name ?? "Unnamed")
        .inspector(isPresented: $environment.showInspector) {
            NavigationStack {
                InspectorScreen(device)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: serviceDiscovery()
    
    func serviceDiscovery() async {
        guard let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) else { return }
        await deviceVM.discoverSupportedServices()
    }
    
    // MARK: disconnect()
    
    func disconnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            Task { @MainActor in
                try await connectedDevicesViewModel.disconnectAndRemoveViewModel(device.id)
                navigationViewModel.selectedCategory = nil
            }
        }
    }
}
