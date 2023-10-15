//
//  ConnectedDeviceList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

fileprivate typealias Device = ConnectedDevicesScreen.ViewModel.Device

struct ConnectedDeviceList<DetailedScreen: View>: View {
    @EnvironmentObject var environment: ConnectedDevicesScreen.ViewModel.Environment
    
    typealias DetailedScreenBuilder = (ConnectedDevicesScreen.ViewModel.Device) -> DetailedScreen
    let detailedScreen: DetailedScreenBuilder?
    
    init(@ViewBuilder detailedScreen: @escaping DetailedScreenBuilder) {
        self.detailedScreen = detailedScreen
    }
    
    init() where DetailedScreen == DeviceDetailsScreen {
        self.detailedScreen = nil
    }
    
    var body: some View {
        List(environment.connectedDevices) { device in
            NavigationLink {
                if let detailedScreen = detailedScreen {
                    detailedScreen(device)
                } else {
                    DeviceDetailsScreen(viewModel: environment.deviceViewModel(device))
                }
            } label: {
                Text(device.name ?? "unnamed")
            }
        }
    }
}


#Preview {
    NavigationStack {
        ConnectedDeviceList {
            Text("connected device: \($0.name ?? "unnamed")")
        }
        .environmentObject(ConnectedDevicesScreen.ViewModel.Environment(connectedDevices: [
            Device(name: "Device 1", id: UUID())
        ]))
    }
}
