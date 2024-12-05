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
    
    private let device: ConnectedDevicesViewModel.Device
    
    // MARK: init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view

    var body: some View {
        List {
            Section("Heart Rate") {
                if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id),
                   let heartRateServiceViewModel = deviceVM.heartRateServiceViewModel {
                    HeartRateView()
                        .environmentObject(heartRateServiceViewModel)
                } else {
                    NoContentView(
                        title: "No Services",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: "No Supported Services"
                    )
                }
            }
            
            Section("Battery") {
                if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id),
                   let batteryViewModel = deviceVM.batteryServiceViewModel {
                    BatteryView()
                        .environmentObject(batteryViewModel)
                } else {
                    NoContentView(
                        title: "No Services",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: "No Supported Services"
                    )
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
    }
}
