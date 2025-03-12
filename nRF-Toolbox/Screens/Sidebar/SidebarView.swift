//
//  SidebarView.swift
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
                if viewModel.connectedDevices.isEmpty {
                    Text("No Connected Devices")
                } else {
                    ForEach(viewModel.connectedDevices) { device in
                        SidebarDeviceView(device)
                            .tag(RootNavigationView.MenuCategory.device)
                    }
                }
            }
            
            Section {
                Text("Open Scanner")
                    .foregroundStyle(Color.universalAccentColor)
                    .centered()
                    .tag(RootNavigationView.MenuCategory.scanner)
            }
            
            Section("Other") {
                Label("About nRF Toolbox", systemImage: "info")
                    .setAccent(.nordicMiddleGrey)
                    .tag(RootNavigationView.MenuCategory.about)
            }
        }
        .navigationTitle("nRF Toolbox")
        .setupNavBarBackground(with: Assets.navBar.color)
    }
}
