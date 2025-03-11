//
//  RootNavigationScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock

struct RootNavigationView: View {

    // MARK: Properties
    
    private static let centralManager = CentralManager()
    
    @StateObject var viewModel = RootNavigationViewModel.shared
    @StateObject var connectedDevicesViewModel = ConnectedDevicesViewModel(centralManager: centralManager)
    
    @StateObject var scannerViewModel = PeripheralScannerScreen.PeripheralScannerViewModel(centralManager: centralManager)

    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var compactPreferredColumn: NavigationSplitViewColumn = .sidebar
    
    // MARK: view
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility, preferredCompactColumn: $compactPreferredColumn) {
            SidebarView()
                .environmentObject(connectedDevicesViewModel)
        } content: {
            switch viewModel.selectedCategory {
            case .scanner:
                PeripheralScannerScreen()
                    .environmentObject(scannerViewModel)
                    .environmentObject(scannerViewModel.environment)
            case .device:
                if let selectedDevice = connectedDevicesViewModel.selectedDevice {
                    DeviceScreen(selectedDevice)
                        .environmentObject(viewModel)
                        .environmentObject(connectedDevicesViewModel)
                } else {
                    EmptyView()
                }
            case .about:
                AboutView()
            case .none:
                EmptyView()
            }
        } detail: {
            if connectedDevicesViewModel.hasSelectedDevice {
                if let deviceVM = connectedDevicesViewModel.selectedDeviceModel() {
                    DeviceDetailsScreen(viewModel: deviceVM)
                        .environmentObject(connectedDevicesViewModel)
                } else {
                    NoContentView(title: "Device is not connected", systemImage: "laptopcomputer.slash")
                }
            } else {
                NoContentView(title: "Device is not selected", systemImage: "laptopcomputer.slash")
            }
        }
        .onAppear {
            scannerViewModel.setupManager()
        }
        .navigationSplitViewStyle(.balanced)
        .accentColor(.white)
        .environmentObject(viewModel)
    }
}
