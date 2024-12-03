//
//  PeripheralScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 30/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock_Collection

private typealias Env = PeripheralInspectorScreen.PeripheralInspectorViewModel.Environment

struct PeripheralInspectorScreen: View {

    let viewModel: PeripheralInspectorViewModel

    var body: some View {
        PeripheralInspectorView()
            .task {
                viewModel.onConnect()
            }
            .environmentObject(viewModel.env)
    }
}

struct PeripheralInspectorView: View {
    @EnvironmentObject private var environment: Env
    @EnvironmentObject private var rootEnv: DeviceDetailsScreen.DeviceDetailsViewModel.Environment
    @EnvironmentObject private var rootNavigationMV: RootNavigationViewModel
    @EnvironmentObject private var connectedDeviceViewModel: ConnectedDevicesViewModel
    
    @State private var disconnectAlertShow = false
    @State private var showAttributeTable = false
    
    #if os(iOS)
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    #endif 

    var body: some View {
        List {
            Section {
                attributeTableNavigator
            }
            
            Section {
                SignalChartView()
                    .environmentObject(environment.signalChartViewModel.environment)
            }
            
            if environment.batteryLevelAvailable {
                Section {
                    BatteryChart(data: environment.batteryLevelData, currentLevel: environment.currentBatteryLevel)
                }
            }
            
            if environment.deviceInfoAvailable {
                Section("Device Information") {
                    DeviceInformationView(deviceInformation: environment.deviceInfo)
                }
            }
            
            Section {
                Button("Disconnect") {
                    disconnectAlertShow = true
                }
                .foregroundStyle(.red)
                .alert("Disconnect", isPresented: $disconnectAlertShow) {
                    Button("Yes") {
                        // TODO: Unselect Device instead
//                        rootNavigationMV.selectedDevice = nil
                        rootEnv.showInspector = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            Task {
                                try await connectedDeviceViewModel.disconnectAndRemoveViewModel(environment.deviceId)
                            }
                        }
                    }
                    Button("No") { }
                } message: {
                    Text("Are you sure you want to cancel peripheral connectior?")
                }

            }
        }
    }
    
    @ViewBuilder
    private var attributeTableNavigator: some View {
#if os(macOS)
        attributeTableButton
#else
        if idiom == .phone {
            attributeTableNavLink
        } else {
            attributeTableButton
        }
#endif
    }
    
    @ViewBuilder
    private var attributeTableNavLink: some View {
        NavigationLink {
            AttributeTableScreen(viewModel: environment.attributeTableViewModel)
        } label: {
            Text("Attribute Table")
        }
    }
    
    @ViewBuilder
    private var attributeTableButton: some View {
        Button("Show Attribute Table") {
            showAttributeTable = true
        }
        .sheet(isPresented: $showAttributeTable) {
            NavigationStack {
                AttributeTableScreen(viewModel: environment.attributeTableViewModel)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAttributeTable = false
                            }
                        }
                    }
                #if os(macOS)
                    .frame(width: 400, height: 500)
                #endif
            }
        }
    }
}

#Preview {
    NavigationStack {
        TabView {
            PeripheralInspectorView()
                .environmentObject(Env(
                    deviceId: UUID(),
                    batteryLevelData: Battery.preview,
                    batteryLevelAvailable: true,
                    deviceInfoAvailable: true,
                    deviceInfo: DeviceInformation(
                        manufacturerName: "Nordic Semiconductor",
                        modelNumber: "nRF52840"
                    )
                ))
                .tabItem { Label("Device", systemImage: "apple.terminal") }
        }
        .navigationTitle("Device Info")
    }
}
