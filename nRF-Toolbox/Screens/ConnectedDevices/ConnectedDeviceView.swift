//
//  ConnectedDeviceView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - ConnectedDeviceView

struct ConnectedDeviceView: View {
    
    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
    
    // MARK: Init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            Text(device.name ?? "Unnamed")
            
            Spacer()
            
            if case .some = device.error {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(Color.nordicRed)
            }
        }
    }
}

