//
//  DeviceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - DeviceScreen

struct DeviceScreen: View {

    // MARK: Environment
    
    @EnvironmentObject var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: view

    var body: some View {
        List {
            Section("Heart Rate") {
                if let selectedDevice = connectedDevicesViewModel.selectedDevice,
                   let deviceVM = connectedDevicesViewModel.deviceViewModel(for: selectedDevice.id),
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
                if let selectedDevice = connectedDevicesViewModel.selectedDevice,
                   let deviceVM = connectedDevicesViewModel.deviceViewModel(for: selectedDevice.id),
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
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connectedDevicesViewModel.selectedDevice?.name ?? "Unnamed")
    }
}
