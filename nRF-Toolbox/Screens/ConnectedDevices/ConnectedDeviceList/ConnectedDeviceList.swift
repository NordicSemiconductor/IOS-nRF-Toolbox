//
//  ConnectedDeviceList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

fileprivate typealias Device = ConnectedDevicesScreen.ViewModel.Device

struct ConnectedDeviceList: View {
    @EnvironmentObject var environment: ConnectedDevicesScreen.ViewModel.Environment
   
    var body: some View {
        List(environment.connectedDevices) { device in
            NavigationLink {
                if let builder = environment.deviceViewModel {
                    DeviceDetailsScreen(viewModel: builder(device))
                } else {
                    #if DEBUG
                    Text("Device Preview")
                    #else
                    fatalError()
                    #endif
                }
            } label: {
                HStack {
                    Text(device.name ?? "unnamed")
                    Spacer()
                    if case .some = device.error {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(Color.nordicRed)
                    }
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        ConnectedDeviceList()
            .environmentObject(ConnectedDevicesScreen.ViewModel.Environment(connectedDevices: [
                Device(name: "Device 1", id: UUID()),
                Device(name: "Device 1", id: UUID(), error: ReadableError(title: "some", message: nil))
            ]))
    }
}
