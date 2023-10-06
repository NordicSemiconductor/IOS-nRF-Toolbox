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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var activeTab = ""
    
    @State var errorActionsDisabled = false
    
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
                    Task {
                        try await peripheralHandler.discover()
                    }
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
                            errorActionsDisabled = true
                            await peripheralHandler.tryToReconnect()
                            errorActionsDisabled = false
                        }
                    }
                    .buttonStyle(NordicPrimary())
                    .disabled(errorActionsDisabled)
                    
                    Button("Remove device") {
                        Task {
                            errorActionsDisabled = true
                            await peripheralHandler.cancelPeripheralConnection()
                            errorActionsDisabled = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .buttonStyle(NordicSecondaryDistructive())
                    .disabled(errorActionsDisabled)
                }
            }
        )
    }
}

struct DeviceDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DeviceDetailsView(peripheralHandler: DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(runningSpeedCadenceSensor), requestReconnect: { _ in }, cancelConnection: { _ in }))
        }
    }
}
