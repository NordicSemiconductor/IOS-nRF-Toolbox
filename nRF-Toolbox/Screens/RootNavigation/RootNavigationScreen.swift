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
import SwiftData

// MARK: - RootNavigationView

struct RootNavigationView: View {

    // MARK: Environment
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    
    // MARK: Properties
    
    @State var rootViewModel = RootNavigationViewModel.shared
    @Environment(ConnectedDevicesViewModel.self) var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    @State private var visibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    
    private let log = NordicLog(category: "RootNavigationView", subsystem: "com.nordicsemi.nrf-toolbox")

    // MARK: view
    
    var body: some View {
        @Bindable var connectedDevicesViewModel = connectedDevicesViewModel
        NavigationSplitView(columnVisibility: $visibility, preferredCompactColumn: $preferredCompactColumn) {
            SidebarView()
                .navigationTitle("nRF Toolbox")
                .navigationBarTitleDisplayMode(.inline)
                .navigationSplitViewColumnWidth(ideal: 420.0)
                .environment(connectedDevicesViewModel)
        } detail: {
            NavigationStack {
                switch (rootViewModel.selectedCategory) {
                case .device(let device):
                    DeviceScreen()
                        .environment(connectedDevicesViewModel)
                        .environment(connectedDevicesViewModel.deviceViewModel(for: device.id)!)
                        .onAppear {
                            log.debug("DeviceScreen opened on details tab.")
                        }
                case .scanner:
                    PeripheralScannerScreen()
                        .environment(connectedDevicesViewModel)
                        .onAppear {
                            log.debug("PeripheralScannerScreen opened on details tab.")
                        }
                case .logs(let tab):
                    LogsScreen(tab: tab)
                        .environment(connectedDevicesViewModel)
                        .onAppear {
                            log.debug("LogsScreen opened on details tab.")
                        }
                case nil:
                    NordicEmptyView()
                        .onAppear {
                            log.debug("Empty view opened on details tab.")
                        }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: horizontalSizeClass) { oldValue, newValue in
            switch (oldValue, newValue) {
            case (.regular, .compact):
                log.debug("Transition from REGULAR size class to COMPACT")
                if case .device = rootViewModel.selectedCategory, connectedDevicesViewModel.selectedDevice != nil {
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
            .setupTranslucentBackground()
        }
        .onAppear {
            connectedDevicesViewModel.setupManager()
        }
        .accentColor(.white)
        .environment(rootViewModel)
    }
}
