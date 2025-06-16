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

    // MARK: Environment
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    
    // MARK: Properties
    
    private static let centralManager = CentralManager()
    
    @StateObject var rootViewModel = RootNavigationViewModel.shared
    @StateObject var connectedDevicesViewModel = ConnectedDevicesViewModel(centralManager: centralManager)
    
    @StateObject var scannerViewModel = PeripheralScannerScreen.PeripheralScannerViewModel(centralManager: centralManager)

    @State private var visibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    
    private let log = NordicLog(category: "RootNavigationView", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init() {
        // Might be deprecated but it works.
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    // MARK: view
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility, preferredCompactColumn: $preferredCompactColumn) {
            SidebarView()
                .navigationTitle("nRF Toolbox")
                .navigationSplitViewColumnWidth(ideal: 300.0)
                .toolbar {
                    Button("", systemImage: "info") {
                        rootViewModel.showAboutView = true
                    }
                }
                .environmentObject(scannerViewModel)
                .environmentObject(connectedDevicesViewModel)
        } detail: {
            NordicEmptyView()
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: horizontalSizeClass) { oldValue, newValue in
            switch (oldValue, newValue) {
            case (.regular, .compact):
                log.debug("Transition from REGULAR size class to COMPACT")
                if rootViewModel.selectedCategory == .device, connectedDevicesViewModel.selectedDevice != nil {
                    preferredCompactColumn = .detail
                } else {
                    preferredCompactColumn = .sidebar
                }
            case (.compact, .regular):
                log.debug("Transition from COMPACT size class to REGULAR")
                visibility = .all
            default:
                return
            }
        }
        .alert("Error", isPresented: $connectedDevicesViewModel.showUnexpectedDisconnectionAlert,
               actions: {
            Button("OK") {
                connectedDevicesViewModel.showUnexpectedDisconnectionAlert = false
            }
        }, message: {
            Text(connectedDevicesViewModel.unexpectedDisconnectionMessage)
        })
        .sheet(isPresented: $rootViewModel.showAboutView) {
            NavigationStack {
                AboutView()
            }
            .setupNavBarBackground(with: Assets.navBar.color)
        }
        .onAppear {
            scannerViewModel.setupManager()
        }
        .accentColor(.white)
        .environmentObject(rootViewModel)
    }
}
