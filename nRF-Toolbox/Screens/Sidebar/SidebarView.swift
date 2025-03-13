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
    @EnvironmentObject var scannerViewModel: PeripheralScannerScreen.PeripheralScannerViewModel
    
    // MARK: view
    
    var body: some View {
        List(selection: $rootViewModel.selectedCategory) {
            Section("Connected Devices") {
                if viewModel.connectedDevices.isEmpty {
                    Text("No Connected Devices")
                } else {
                    ForEach(viewModel.connectedDevices) { device in
                        NavigationLink {
                            DeviceScreen(device)
                                .environmentObject(rootViewModel)
                                .environmentObject(viewModel)
                        } label: {
                            SidebarDeviceView(device)
                                .tag(RootNavigationView.MenuCategory.device)
                        }
                        
                        #if DEBUG
                        if let deviceViewModel = viewModel.deviceViewModel(for: device.id) {
                            NavigationLink("Old Device Details") {
                                DeviceDetailsScreen(viewModel: deviceViewModel)
                                    .environmentObject(viewModel)
                            }
                        }
                        #endif
                    }
                }
            }
            .foregroundColor(Color(uiColor: .label))
            
            Section {
                NavigationLink {
                    PeripheralScannerScreen()
                        .environmentObject(scannerViewModel)
                        .environmentObject(scannerViewModel.environment)
                } label: {
                    Text("Open Scanner")
                        .foregroundStyle(Color.universalAccentColor)
                        .centered()
                        .tag(RootNavigationView.MenuCategory.scanner)
                }
            }
            
            Section("Other") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About nRF Toolbox", systemImage: "info")
                        .setAccent(.nordicMiddleGrey)
                        .tag(RootNavigationView.MenuCategory.about)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("nRF Toolbox")
        .setupNavBarBackground(with: Assets.navBar.color)
    }
}
