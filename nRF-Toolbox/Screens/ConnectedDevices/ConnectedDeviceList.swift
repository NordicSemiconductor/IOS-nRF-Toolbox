//
//  ConnectedDeviceList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

fileprivate typealias Device = ConnectedDevicesViewModel.Device

// MARK: - ConnectedDeviceList

struct ConnectedDeviceList: View {
    
    // MARK: Environment
    
    @EnvironmentObject var environment: ConnectedDevicesViewModel.Environment
    @EnvironmentObject var rootNavigationVM: RootNavigationViewModel
   
    // MARK: view
    
    var body: some View {
        List(environment.connectedDevices, selection: $rootNavigationVM.selectedDevice) { device in
            HStack {
                Text(device.name ?? "Unnamed")
                
                Spacer()
                
                if case .some = device.error {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(Color.nordicRed)
                }
            }
            .tag(device.id)
        }
    }
}
