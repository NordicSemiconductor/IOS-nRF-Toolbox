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
    
    // MARK: init
    
    init() {
        // Might be deprecated but it works.
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    // MARK: view
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            SidebarView()
                .navigationTitle("nRF Toolbox")
                .navigationSplitViewColumnWidth(ideal: 300.0)
                .toolbar {
                    Button("", systemImage: "info") {
                        viewModel.showStartInfo = true
                    }
                }
                .environmentObject(scannerViewModel)
                .environmentObject(connectedDevicesViewModel)
        } content: {
            NordicEmptyView()
        } detail: {
            NordicEmptyView()
        }
        .navigationSplitViewStyle(.balanced)
        .alert("Error", isPresented: $connectedDevicesViewModel.showUnexpectedDisconnectionAlert,
               actions: {
            Button("OK") {
                connectedDevicesViewModel.showUnexpectedDisconnectionAlert = false
            }
        }, message: {
            Text(connectedDevicesViewModel.unexpectedDisconnectionMessage)
        })
        .sheet(isPresented: $viewModel.showStartInfo) {
            NavigationStack {
                AboutView()
            }
            .setupNavBarBackground(with: Assets.navBar.color)
        }
        .onAppear {
            scannerViewModel.setupManager()
        }
        .accentColor(.white)
        .environmentObject(viewModel)
    }
}
