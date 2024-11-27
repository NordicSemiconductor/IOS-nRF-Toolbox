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
            Section("Devices") {
                if viewModel.environment.connectedDevices.isEmpty {
                    Text("No Connected Devices")
                } else {
                    ForEach(viewModel.environment.connectedDevices) { device in
                        Text(device.name ?? "Unnamed Device")
                    }
                }
            }
            
            Section {
                Text("Open Scanner")
                    .accentColor(.universalAccentColor)
                    .centered()
                    .tag(RootNavigationView.MenuCategory.devices.id)
            }
            
            Section("Other") {
                Text("About")
                    .tag(RootNavigationView.MenuCategory.about.id)
                    .disabled(true)
            }
        }
        .navigationTitle("nRF Toolbox")
    }
}
