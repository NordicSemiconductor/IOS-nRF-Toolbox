//
//  RootNavigationScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
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
                .navigationTitle("nRF Toolbox")
                .setupNavBarBackground(with: Assets.navBar.color)
                .toolbar {
                    Button("", systemImage: "info.circle") {
                        viewModel.showStartInfo = true
                    }
                }
                .environmentObject(scannerViewModel)
                .environmentObject(connectedDevicesViewModel)
        }
        .sheet(isPresented: $viewModel.showStartInfo) {
            AboutView()
        }
        .onAppear {
            scannerViewModel.setupManager()
        }
        .accentColor(.white)
        .environmentObject(viewModel)
    }
}
