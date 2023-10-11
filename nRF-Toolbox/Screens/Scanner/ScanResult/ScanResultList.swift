//
//  ScanResultList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

fileprivate typealias Env = PeripheralScannerScreen.ViewModel.PreviewEnvironment

struct ScanResultList: View {
    @EnvironmentObject private var environment: Env
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                ForEach(environment.devices) { device in
                    VStack {
                        Button {
                            Task {
                                await environment.connect(device)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                ScanResultItem(name: device.name, rssi: device.rssi, services: device.services)
                                Spacer()
                                if environment.connectingDevice == device {
                                    ProgressView()
                                } else {
                                    Button {
                                        // TODO: Open info screen
                                    } label: {
                                        Image(systemName: "info.circle")
                                    }
                                }
                            }
                        }
                        #if os(macOS)
                        Divider()
                        #endif
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } footer: {
                Text("Select the device to establish connection or press 􀅴 to open detailed information")
            }

        }
    }
}

#Preview {
    ScanResultList()
        .environmentObject(Env(devices: [
            PeripheralScannerScreen.ViewModel.ScanResult(name: "Device", rssi: -59, id: UUID(), services: []),
            PeripheralScannerScreen.ViewModel.ScanResult(name: "Device", rssi: -69, id: UUID(), services: []),
            PeripheralScannerScreen.ViewModel.ScanResult(name: "Device", rssi: -79, id: UUID(), services: []),
        ]))
}
