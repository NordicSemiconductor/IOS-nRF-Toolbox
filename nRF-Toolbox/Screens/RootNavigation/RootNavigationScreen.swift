//
//  RootNavigationScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct RootNavigationView: View {

    @StateObject var viewModel = RootNavigationViewModel.shared
    @StateObject var connectedDevicesViewModel = ConnectedDevicesViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(connectedDevicesViewModel)
        } content: {
            ConnectedDevicesScreen()
                .environmentObject(connectedDevicesViewModel)
        } detail: {
            if let deviceId = viewModel.selectedDevice {
                if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: deviceId) {
                    DeviceDetailsScreen(viewModel: deviceVM)
                        .environmentObject(connectedDevicesViewModel)
                } else {
                    NoContentView(title: "Device is not connected", systemImage: "laptopcomputer.slash")
                }
            } else {
                NoContentView(title: "Device is not selected", systemImage: "laptopcomputer.slash")
            }
        }
        .accentColor(.white)
        .environmentObject(viewModel)
    }
}
