//
//  RootNavigationScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock

// MARK: - RootNavigationView

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
        NavigationView {
            SidebarView()
                .environmentObject(scannerViewModel)
                .environmentObject(connectedDevicesViewModel)
        }
        .onAppear {
            scannerViewModel.setupManager()
        }
        .accentColor(.white)
        .environmentObject(viewModel)
    }
}
