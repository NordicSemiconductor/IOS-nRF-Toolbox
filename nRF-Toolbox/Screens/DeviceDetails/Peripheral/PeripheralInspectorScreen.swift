//
//  PeripheralScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 30/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock_Collection

private typealias Env = PeripheralInspectorViewModel.Environment

// MARK: - PeripheralInspectorView

struct PeripheralInspectorView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var rootEnv: DeviceDetailsViewModel.Environment
    @EnvironmentObject private var rootNavigationMV: RootNavigationViewModel
    @EnvironmentObject private var connectedDeviceViewModel: ConnectedDevicesViewModel
    
    // MARK: Private Properties
    
    @State private var disconnectAlertShow = false

    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
        
    // MARK: init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view
    
    var body: some View {
        NavigationView {
            List {
                //            Section {
                //                SignalChartView()
                //                    .environmentObject(environment.signalChartViewModel.environment)
                //            }
                //
                //            if environment.batteryLevelAvailable {
                //                Section {
                //                    BatteryChart(data: environment.batteryLevelData, currentLevel: environment.currentBatteryLevel)
                //                }
                //            }
                //
                //            Section("GATT") {
                //                attributeTableNavLink
                //            }
                //
                //            if environment.deviceInfoAvailable {
                //                Section("Device Info") {
                //                    DeviceInformationView(environment.deviceInfo)
                //                }
                //            }
                
                Section {
                    Button("Dismiss") {
                        rootEnv.showInspector = false
                    }
                    .tint(.universalAccentColor)
                    .centered()
                }
                
                Section {
                    Button("Disconnect") {
                        disconnectAlertShow = true
                    }
                    .foregroundStyle(.red)
                    .centered()
                    .alert("Disconnect", isPresented: $disconnectAlertShow) {
                        Button("Yes") {
                            // TODO: Unselect Device instead
                            //                        rootNavigationMV.selectedDevice = nil
                            rootEnv.showInspector = false
                            //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            //                            Task {
                            //                                try await connectedDeviceViewModel.disconnectAndRemoveViewModel(environment.deviceId)
                            //                            }
                            //                        }
                        }
                        Button("No") { }
                    } message: {
                        Text("Are you sure you want to cancel peripheral connectior?")
                    }
                }
            }
        }
    }
    
    // MARK: attributeTableNavLink
    
//    @ViewBuilder
//    private var attributeTableNavLink: some View {
//        NavigationLink {
//            AttributeTableScreen(viewModel: environment.attributeTableViewModel)
//        } label: {
//            Label("Attribute Table", systemImage: "list.dash")
//                .setAccent(.nordicBlue)
//        }
//    }
}
