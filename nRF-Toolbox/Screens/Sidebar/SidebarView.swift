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
                                    .tag(RootNavigationView.MenuCategory.device)
                                    .environmentObject(rootViewModel)
                                    .environmentObject(viewModel)
                                    .environmentObject(deviceViewModel)
                            } label: {
                                SidebarDeviceView(device)
                            }
                            .isDetailLink(true)
                        }
                    }
                }
            }
            
            Section("Scanner") {
                NavigationLink {
                    PeripheralScannerScreen()
                        .tag(RootNavigationView.MenuCategory.scanner)
                        .environmentObject(viewModel)
                } label: {
                    Label("Connect to Device", systemImage: "dot.radiowaves.right")
                        .setAccent(.universalAccentColor)
                }
                .isDetailLink(true)
            }
            
            Section {
                Button {
                    rootViewModel.showAboutView = true
                } label: {
                    Label("About nRF Toolbox", systemImage: "app.gift")
                }
                
                Link(destination: URL(string:  "https://github.com/NordicSemiconductor/IOS-nRF-Toolbox")!) {
                    Label("Source Code (GitHub)", systemImage: "keyboard")
                }
                
                Link(destination: URL(string: "https://devzone.nordicsemi.com/")!) {
                    Label("Help (Nordic DevZone)", systemImage: "lifepreserver")
                }
            } header: {
                Text("Links")
            } footer: {
                Text(Constant.copyright)
                    .foregroundStyle(Color.nordicMiddleGrey)
            }
            .setAccent(.universalAccentColor)
            .tint(.primarylabel)
        }
        .tint(Color.universalAccentColor)
        .listStyle(.insetGrouped)
        .setupNavBarBackground(with: Assets.navBar.color)
    }
}
