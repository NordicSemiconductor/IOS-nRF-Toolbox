//
//  DeviceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - DeviceScreen

struct DeviceScreen: View {

    // MARK: Environment
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject private var deviceViewModel: DeviceDetailsViewModel
    @EnvironmentObject private var navigationViewModel: RootNavigationViewModel
    @EnvironmentObject private var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
    private let log = NordicLog(category: "DeviceScreen", subsystem: "com.nordicsemi.nrf-toolbox")
        
    // MARK: init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view

    var body: some View {
        List {
            if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) {
                deviceVM.supportedServiceViews()
                    .disabled(device.status.hashValue != ConnectedDevicesViewModel.Device.Status.connected.hashValue)
            }
            
            Section("Device Information") {
                Button("Open Inspector", systemImage: "info.circle") {
                    deviceViewModel.showInspector.toggle()
                }
                .foregroundStyle(Color.universalAccentColor)
                .centered()
            }
            
            Section("Troubleshooting") {
                DisclosureGroup {
                    Text("Turn off and on Bluetooth from Settings (not Control Center) to clear the cache.")
                        .foregroundStyle(Color.secondary)
                } label: {
                    Label("Can't find your service?", systemImage: "exclamationmark.magnifyingglass")
                }
                .accentColor(.universalAccentColor)
            }
            
            Section("Connection") {
                switch device.status {
                case .userInitiatedDisconnection:
                    ProgressView()
                case .connected:
                    Button("Disconnect") {
                        disconnect()
                    }
                    .foregroundStyle(Color.red)
                    .centered()
                case .error(let error):
                    Label(error.localizedDescription, systemImage: "exclamationmark.circle")
                        .foregroundStyle(Color.nordicRed)
                    
                    // TODO: Restore.
//
//                    Button("Reconnect") {
//                        reconnect()
//                    }
//                    .foregroundStyle(Color.universalAccentColor)
//                    .centered()
                }
            }
            
            if case .error = device.status {
                Section {
                    Button("Clear Device") {
                        connectedDevicesViewModel.clearViewModel(device.id)
                        dismiss()
                    }
                    .foregroundStyle(Color.universalAccentColor)
                    .centered()
                }
            }
        }
        .taskOnce {
            log.debug("DeviceScreen \(#function)")
            guard let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) else { return }
            await deviceVM.discoverSupportedServices()
        }
        .onDisappear {
            log.debug("DeviceScreen DISAPPEARED !!!")
            Task { @MainActor in
                guard let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) else { return }
                await deviceVM.onDisconnect()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connectedDevicesViewModel.selectedDevice?.name ?? "Unnamed")
        .inspector(isPresented: $deviceViewModel.showInspector) {
            NavigationStack {
                InspectorScreen(device)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(connectedDevicesViewModel.objectWillChange) {
            guard connectedDevicesViewModel.connectedDevices.firstIndex(where: \.id, equals: device.id) == nil else { return }
            log.debug("Device \(device) not found in Connected Devices anymore. Dismissing.")
            dismiss()
        }
    }
    
    // MARK: reconnect()
    
    func reconnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            Task { @MainActor in
                await connectedDevicesViewModel.deviceViewModel(for: device.id)?.reconnect()
            }
        }
    }
    
    // MARK: disconnect()
    
    func disconnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            Task { @MainActor in
                try await connectedDevicesViewModel.disconnectAndRemoveViewModel(device.id)
                log.debug("Finished disconnectAndRemoveViewModel(\(device.id))")
                dismiss()
            }
        }
    }
}
