//
//  DeviceDetailsView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock
import iOS_Common_Libraries

struct DeviceDetailsView: View {
    @ObservedObject var peripheralHandler: DeviceDetailsViewModel
    @State private var activeTab = ""
    
    var body: some View {
        if let e = peripheralHandler.disconnectedError {
            errorView(error: e)
        } else {
            serviceView()
        }
    }
    
    @ViewBuilder
    private func serviceView() -> some View {
        TabView(selection: $activeTab) {
            ForEach(peripheralHandler.serviceHandlers, id: \.id) { service in
                ServiceView(service: service)
                    .tabItem {
                        Label {
                            Text(service.name)
                        } icon: {
                            service.image
                        }
                    }
                    .tag(service.id)
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
            .tag("attribute")
        }
        .navigationTitle(peripheralHandler.cbPeripheral.name.deviceName)
    }
    
    @ViewBuilder
    private func errorView(error: Error) -> some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "Peripheral Disconnected",
                secondaryText: error.localizedDescription,
                systemName: "point.3.connected.trianglepath.dotted"
            ),
            actions: {
                VStack {
                    Button("Reconnect") {
                        Task {
                            await peripheralHandler.tryToReconnect()
                        }
                    }
                    .buttonStyle(NordicPrimary())
                    
                    Button("Remove device") {
                        // TODO: Remove Device
                    }
                    .buttonStyle(NordicSecondaryDistructive())
                }
            }
        )
    }
}

struct DeviceDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            //        List {
            DeviceDetailsView(peripheralHandler: DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(runningSpeedCadenceSensor), requestReconnect: { _ in }))
            //        }
            //        .navigationTitle("Device")
        }
    }
}
