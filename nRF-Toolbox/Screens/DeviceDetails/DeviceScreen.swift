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
    
    @EnvironmentObject var navigationViewModel: RootNavigationViewModel
    @EnvironmentObject var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: Properties
    
    @State private var showInspector: Bool = false
    
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
        .listStyle(.insetGrouped)
        .navigationTitle(connectedDevicesViewModel.selectedDevice?.name ?? "Unnamed")
        .inspector(isPresented: $showInspector) {
            peripheralInspectorScreen
        }
        .toolbar {
            Button {
                showInspector.toggle()
            } label: {
                Image(systemName: "info")
                    .symbolVariant(.circle)
            }
        }
    }
    
    // MARK: inspector
    
    @ViewBuilder
    private var peripheralInspectorScreen: some View {
        if let deviceViewModel = connectedDevicesViewModel.deviceViewModel(for: device.id),
           let peripheralViewModel = deviceViewModel.environment.peripheralViewModel {
            PeripheralInspectorScreen(viewModel: peripheralViewModel)
                .tabItem {
                    Label("Peripheral", systemImage: "terminal")
                }
        } else {
            NoContentView(title: "No View Model", systemImage: "plus")
        }
    }
}
