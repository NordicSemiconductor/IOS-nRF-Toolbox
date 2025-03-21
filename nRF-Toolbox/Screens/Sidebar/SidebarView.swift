//
//  SidebarView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 14/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - SidebarView

struct SidebarView: View {
    
    // MARK: Environment
    
    @EnvironmentObject var rootViewModel: RootNavigationViewModel
    @EnvironmentObject var viewModel: ConnectedDevicesViewModel
    @EnvironmentObject var scannerViewModel: PeripheralScannerScreen.PeripheralScannerViewModel
    
    // MARK: view
    
    var body: some View {
        List(selection: $rootViewModel.selectedCategory) {
            Section("Connected") {
                if viewModel.connectedDevices.isEmpty {
                    NoContentView(title: "No Connected Devices", systemImage: "cable.connector.slash", description: "Open the Scanner from below to connect to one or multiple Devices.")
                } else {
                    ForEach(viewModel.connectedDevices) { device in
                        if let deviceViewModel = viewModel.deviceViewModel(for: device.id) {
                            NavigationLink {
                                DeviceScreen(device)
                                    .environmentObject(rootViewModel)
                                    .environmentObject(viewModel)
                                    .environmentObject(deviceViewModel.environment)
                            } label: {
                                SidebarDeviceView(device)
                                    .tag(RootNavigationView.MenuCategory.device)
                            }
                        }
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
                    Label("Open Scanner", systemImage: "dot.radiowaves.right")
                        .setAccent(.universalAccentColor)
                        .tag(RootNavigationView.MenuCategory.scanner)
                }
            }
            
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About nRF Toolbox", systemImage: "info")
                        .setAccent(.nordicMiddleGrey)
                        .tag(RootNavigationView.MenuCategory.about)
                }
            } header: {
                Text("Other")
            } footer: {
                Text(Constant.copyright)
                    .foregroundStyle(Color.nordicMiddleGrey)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("nRF Toolbox")
        .setupNavBarBackground(with: Assets.navBar.color)
    }
}
