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
                    ForEach(Array(viewModel.connectedDevices.enumerated()), id: \.element.id) { index, device in
                        let isSelected = rootViewModel.selectedCategory == .device(device)
                        Button(action: {
                            rootViewModel.selectedCategory = RootNavigationView.MenuCategory.device(device)
                        }, label: {
                            SidebarDeviceView(device)
                                .setAccent(isSelected ? Color.white : .nordicBlue)
                                .tint(isSelected ? Color.white : .primarylabel)
                        })
                        .listRowBackground(isSelected ? Color.universalAccentColor : nil)
                        .accessibilityIdentifier("device_item_\(index)")
                    }
                }
            }
            
            Section("Scanner") {
                let isSelected = rootViewModel.selectedCategory == .scanner
                Button(action: {
                    rootViewModel.selectedCategory = RootNavigationView.MenuCategory.scanner
                }, label: {
                    Label("Connect to Device", systemImage: "dot.radiowaves.right")
                        .setAccent(isSelected ? Color.white : .nordicBlue)
                        .tint(isSelected ? Color.white : .primarylabel)
                })
                .listRowBackground(isSelected ? Color.universalAccentColor : nil)
                .accessibilityIdentifier("scannerButton")
            }
            
            Section {
                Button {
                    rootViewModel.showAboutView = true
                } label: {
                    Label("About nRF Toolbox", systemImage: "app.gift")
                }
                
                SourceCodeLinkView(url: URL(string:  "https://github.com/NordicSemiconductor/IOS-nRF-Toolbox")!)
                
                DevZoneLinkView()
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
    }
}
