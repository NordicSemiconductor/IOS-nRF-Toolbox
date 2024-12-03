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
    
//    let viewModel: HeartRateViewModel
    @EnvironmentObject var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: view

    var body: some View {
        VStack {
            ConnectedDevicePicker()
            
            //        if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: deviceId) {
            //            DeviceDetailsScreen(viewModel: deviceVM)
            //                .environmentObject(connectedDevicesViewModel)
            //        } else {
            //            NoContentView(title: "Device is not connected", systemImage: "laptopcomputer.slash")
            //        }
            NoContentView(
                title: "No Services",
                systemImage: "list.bullet.rectangle.portrait",
                description: "No Supported Services"
            )
        }
        
        
//        HeartRateView()
//            .environmentObject(viewModel.env)
//            .task {
//                viewModel.onConnect()
//            }
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
