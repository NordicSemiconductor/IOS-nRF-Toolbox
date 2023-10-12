//
//  ConnectedDeviceList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

fileprivate typealias Device = ConnectedDevicesScreen.ViewModel.Device

struct ConnectedDeviceList: View {
    @EnvironmentObject var environment: ConnectedDevicesScreen.ViewModel.Environment
    
    var body: some View {
        List(environment.connectedDevices) { device in
            NavigationLink {
                EmptyView()
            } label: {
                Text(device.name ?? "n/a")
            }
        }
    }
}


#Preview {
    ConnectedDeviceList()
        .environmentObject(ConnectedDevicesScreen.ViewModel.Environment(connectedDevices: [
            Device(name: "Device 1", id: UUID())
        ]))
}
