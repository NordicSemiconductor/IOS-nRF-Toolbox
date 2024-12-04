//
//  HeartRateScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - HeartRateScreen

struct HeartRateScreen: View {

    // MARK: Environment
    
    @EnvironmentObject var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: view

    var body: some View {
        List {
            Section {
                ConnectedDevicePicker()
            }
            .listRowSeparator(.hidden)
            
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
                    Text("Battery Detected")
                        .task {
                            do {
                                try await batteryViewModel.startListening()
                            } catch {
                                
                            }
                        }
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

// MARK: - HeartRateView

struct HeartRateView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: HeartRateScreen.HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
                .task {
                    await viewModel.prepare()
                }
        } else {
            HeartRateChart()
        }
    }
}
