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
            
            if let error = deviceViewModel.errors?.minorError {
                Section("Minor error") {
                    Text(error.localizedDescription)
                        .foregroundStyle(Color.nordicRed)
                }
            }
            
            if let error = deviceViewModel.errors?.criticalError {
                Section("Critical error") {
                    Text(error.localizedDescription)
                        .foregroundStyle(Color.nordicRed)
                }
            }
            
            Section("Device Information") {
                Button("Open Inspector", systemImage: "info.circle") {
                    deviceViewModel.showDeviceSheet = true
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
                        .centered()
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
        .task {
            log.debug("DeviceScreen.task()")
            connectedDevicesViewModel.selectedDevice = device
        }
        .onDisappear {
            log.debug("DeviceScreen.onDisappear()")
        }
        .listStyle(.insetGrouped)
        .navigationTitle(device.name ?? "Unnamed")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $deviceViewModel.showDeviceSheet) {
            NavigationStack {
                InspectorScreen(device)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .setupTranslucentBackground()
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
