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
                        if device != .Unselected {
                            ConnectedDeviceView(device, isSelected: viewModel.environment.selectedDevice == device)
                        }
                    }
                }
                
                Text("Open Scanner")
                    .foregroundStyle(Color.universalAccentColor)
                    .centered()
                    .tag(RootNavigationView.MenuCategory.scanner)
            }
            
            Section("Services") {
                Label("Heart Rate Monitor (HRM)", systemImage: "heart.fill")
                    .accentColor(.nordicRed)
                    .tag(RootNavigationView.MenuCategory.hrm)
            }
            
            Section("Other") {
                Text("About nRF Toolbox")
                    .tag(RootNavigationView.MenuCategory.about)
                    .disabled(true)
            }
        }
        .navigationTitle("nRF Toolbox")
        .setupNavBarBackground(with: Assets.navBar.color)
    }
}
