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
                    Section("Heart Rate") {
                        HeartRateView()
                            .environmentObject(heartRateServiceViewModel)
                    }
                }
                
                if let temperatureServiceViewModel = deviceVM.temperatureServiceViewModel {
                    Section("Temperature") {
                        TemperatureView()
                            .environmentObject(temperatureServiceViewModel)
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
        .task {
            guard let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) else { return }
            await deviceVM.discoverSupportedServices()
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connectedDevicesViewModel.selectedDevice?.name ?? "Unnamed")
        .inspector(isPresented: $environment.showInspector) {
            PeripheralInspectorScreen()
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
