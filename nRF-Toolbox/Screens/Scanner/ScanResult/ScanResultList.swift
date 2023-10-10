//
//  ScanResultList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

fileprivate typealias Env = PeripheralScannerScreen.ViewModel.PreviewEnvironment

struct ScanResultList: View {
    @EnvironmentObject private var environment: Env
    
    var body: some View {
        List {
            Section {
                ForEach(environment.devices) { device in
                    VStack {
                        Button {
                            Task {
                                environment.connect(device)
                            }
                        } label: {
                            HStack {
                                ScanResultItem(
                                    name: device.name,
                                    rssi: device.rssi,
                                    services: device.knownServices,
                                    otherServices: device.services.count - device.knownServices.count
                                )
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
        .environmentObject(Env(devices: []))
}
