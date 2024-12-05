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
                if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: connectedDevicesViewModel.selectedDevice.id),
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
                if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: connectedDevicesViewModel.selectedDevice.id),
                   let batteryViewModel = deviceVM.batteryServiceViewModel {
                    BatteryView()
                        .task {
                            do {
                                try await batteryViewModel.startListening()
                            } catch {
                                
                            }
                        }
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
        .navigationTitle("Heart Rate Monitor")
    }
}
