//
//  DeviceDetailsView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock

struct DeviceDetailsView: View {
    @ObservedObject var peripheralHandler: DeviceDetailsViewModel
    
    var body: some View {
        TabView {
            ForEach(peripheralHandler.serviceHandlers, id: \.id) { service in
                ServiceView(service: service)
                    .tabItem {
                        Label {
                            Text(service.name)
                        } icon: {
                            service.image
                        }
                    }
            }
            AttributeTableView(
                attributeTable: peripheralHandler.attributeTable,
                discoverTableAction: {
                    peripheralHandler.discover()
                }
            )
            .tabItem {
                Label {
                    Text("Device Details")
                } icon: {
                    Image(systemName: "person.fill")
                }
            }
        }
        .navigationTitle(peripheralHandler.cbPeripheral.name.deviceName)
    }
}

struct DeviceDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            //        List {
            DeviceDetailsView(peripheralHandler: DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(runningSpeedCadenceSensor)))
            //        }
            //        .navigationTitle("Device")
        }
    }
}
