//
//  ConnectedDevicesView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct ConnectedDevicesView: View {
    @EnvironmentObject var viewModel: CentralManagerHelper
    @State var selectedService: String?
    
    @State var showScanner = false
    @State var counter = 0
    
    var body: some View {
        VStack {
            if viewModel.peripheralManagers.isEmpty {
                emptyState.padding()
            } else {
                deviceList
            }
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                PeripheralScannerView()
                #if os(macOS)
                    .frame(minWidth: 400, minHeight: 450)
                #endif
            }
        }
    }
    
    @ViewBuilder
    var emptyState: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "No Connected Devices",
                // TODO: Is it correct message?
                secondaryText: "Scan for devices and connect to peripheral to begin",
                systemName: "antenna.radiowaves.left.and.right"
            ),
            actions: {
                Button("Start Scan") {
                    showScanner = true
                }
                .buttonStyle(NordicPrimary())
            }
        )
    }
    
    var deviceList: some View {
        List {
            ForEach(viewModel.peripheralManagers) { peripheral in
                NavigationLink {
                    DeviceDetailsView(peripheralHandler: peripheral)
                } label: {
                    DeviceItem(peripheral: peripheral)
                }
            }
            Button("Connect another device") {
               showScanner = true
            }
        }
    }
}

struct ConnectedDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                ConnectedDevicesView()
                    .navigationTitle("Connected Devices")
                    .environmentObject(CentralManagerHelperPreview() as CentralManagerHelper)
            }
            
            NavigationStack {
                ConnectedDevicesView()
                    .navigationTitle("Connected Devices")
                    .environmentObject(CentralManagerHelperPreview(generateDevices: true) as CentralManagerHelper)
            }
        }
    }
}
