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
            
            Section("Scanner") {
                NavigationLink {
                    PeripheralScannerScreen()
                        .environmentObject(scannerViewModel)
                        .environmentObject(scannerViewModel.environment)
                } label: {
                    Label("Connect to Device", systemImage: "dot.radiowaves.right")
                        .setAccent(.universalAccentColor)
                        .tag(RootNavigationView.MenuCategory.scanner)
                }
            }
            
            Section {
                Link(destination: URL(string:  "https://github.com/NordicSemiconductor/IOS-nRF-Toolbox")!) {
                    Label("Source Code (GitHub)", systemImage: "keyboard")
                        .labelStyle(.colorIconOnly(.universalAccentColor))
                        .tint(.primarylabel)
                }
                
                Link(destination: URL(string: "https://devzone.nordicsemi.com/")!) {
                    Label("Help (Nordic DevZone)", systemImage: "lifepreserver")
                        .labelStyle(.colorIconOnly(.universalAccentColor))
                        .tint(.primarylabel)
                }
            } header: {
                Text("Links")
            } footer: {
                Text(Constant.copyright)
                    .foregroundStyle(Color.nordicMiddleGrey)
            }
        }
        .listStyle(.insetGrouped)
    }
}
