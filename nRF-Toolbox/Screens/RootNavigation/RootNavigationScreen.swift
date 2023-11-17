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
        } content: {
            ConnectedDevicesScreen()
                .environmentObject(connectedDevicesViewModel)
        } detail: {
            if let deviceId = viewModel.selectedDevice {
                if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: deviceId) {
                    DeviceDetailsScreen(viewModel: deviceVM)
                } else {
                    NoContentView(title: "Device is not connected", systemImage: "laptopcomputer.slash")
                }
            } else {
                NoContentView(title: "Device is not selected", systemImage: "laptopcomputer.slash")
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    RootNavigationView()
}
