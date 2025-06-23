//
//  InspectorScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 30/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock_Collection

// MARK: - InspectorScreen

struct InspectorScreen: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var deviceViewModel: DeviceDetailsViewModel
    @EnvironmentObject private var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: Private Properties
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
        
    private var deviceIsConncted: Bool {
        switch device.status {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    // MARK: init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section("GATT") {
                NavigationLink {
                    AttributeTableScreen(deviceViewModel.attributeTable)
                } label: {
                    Label("Attribute Table", systemImage: "list.dash")
                        .setAccent(.nordicBlue)
                }
            }
            
            if let deviceVM = connectedDevicesViewModel.deviceViewModel(for: device.id) {
                if let signalViewModel = deviceVM.signalViewModel {
                    Section {
                        SignalChart()
                            .onAppear {
                                signalViewModel.startTimer()
                            }
                            .onDisappear {
                                signalViewModel.stopTimer()
                            }
                            .environmentObject(signalViewModel.environment)
                    }
                    .disabled(!deviceIsConncted)
                }
                
                if let batteryServiceViewModel = deviceVM.batteryServiceViewModel {
                    Section {
                        BatteryView()
                            .environmentObject(batteryServiceViewModel)
                    }
                    .disabled(!deviceIsConncted)
                }
                
                if let deviceInfo = deviceVM.deviceInfo {
                    Section("Device Info") {
                        DeviceInformationView(deviceInfo)
                    }
                }
            }
            
            if deviceIsConncted {
                Section {
                    Button("Disconnect") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            Task { @MainActor in
                                deviceViewModel.showDeviceSheet = false
                                try await connectedDevicesViewModel.disconnectAndRemoveViewModel(device.id)
                            }
                        }
                    }
                    .foregroundStyle(.red)
                    .centered()
                }
            }
        }
        .navigationTitle("Device Inspector")
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    dismiss()
                }
                .tint(Color.white)
            }
        }
    }
}
