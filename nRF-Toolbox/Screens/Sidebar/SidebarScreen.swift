//
//  SidebarScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 14/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - SidebarView

struct SidebarView: View {
    
    // MARK: Environment
    
    @EnvironmentObject var rootViewModel: RootNavigationViewModel
    @EnvironmentObject var viewModel: ConnectedDevicesViewModel
    
    // MARK: view
    
    var body: some View {
        List(selection: $rootViewModel.selectedCategory) {
            Section("Connected Devices") {
                if viewModel.environment.connectedDevices.isEmpty {
                    Text("No Connected Devices")
                } else {
                    ForEach(viewModel.environment.connectedDevices) { device in
                        Button {
                            rootViewModel.selectedDevice = device.id
                        } label: {
                            ConnectedDeviceView(device)
                        }
                    }
                }
            }
            
            Section {
                Text("Open Scanner")
                    .foregroundStyle(Color.universalAccentColor)
                    .centered()
                    .tag(RootNavigationView.MenuCategory.devices.id)
            }
            
            Section("Other") {
                Text("About nRF Toolbox")
                    .tag(RootNavigationView.MenuCategory.about.id)
                    .disabled(true)
            }
        }
        .navigationTitle("nRF Toolbox")
        .setupNavBarBackground(with: Assets.navBar.color)
    }
}
