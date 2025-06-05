//
//  ConnectedDeviceView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import iOS_Bluetooth_Numbers_Database

// MARK: - SidebarDeviceView

struct SidebarDeviceView: View {
    
    // MARK: Environment
    
    @EnvironmentObject var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
    private let advertisedServices: Set<Service>
    
    // MARK: Init
    
    init(_ device: ConnectedDevicesViewModel.Device, advertising: Set<Service>) {
        self.device = device
        self.advertisedServices = advertising
    }
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(device.name ?? "Unnamed", systemImage: "cpu")
                .accentColor(.universalAccentColor)
                .padding(.bottom, 4)
            
            ServiceBadgeGroup(advertisedServices)
                .padding(.leading, 42)
                .padding(.bottom, 8)
            
            switch device.status {
            case .connected, .userInitiatedDisconnection:
                EmptyView()
            case .error(let error):
                Label("Error: \(error.localizedDescription)", systemImage: "exclamationmark.circle")
                    .accentColor(.nordicRed)
                    .font(.caption)
            }
        }
    }
}

