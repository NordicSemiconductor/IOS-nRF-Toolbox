//
//  HeartRateScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = HeartRateScreen.HeartRateViewModel.Environment

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
            
            if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: connectedDevicesViewModel.selectedDevice.id),
               let heartRateServiceViewModel = deviceVM.heartRateServiceViewModel {
                HeartRateView()
                    .environmentObject(heartRateServiceViewModel.env)
            } else {
                NoContentView(
                    title: "No Services",
                    systemImage: "list.bullet.rectangle.portrait",
                    description: "No Supported Services"
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Heart Rate Monitor")
    }
}

// MARK: - HeartRateView

struct HeartRateView: View {
    
    @EnvironmentObject private var environment: Env
    
    var body: some View {
        if environment.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
        } else {
            HeartRateChart()
        }
    }
}
