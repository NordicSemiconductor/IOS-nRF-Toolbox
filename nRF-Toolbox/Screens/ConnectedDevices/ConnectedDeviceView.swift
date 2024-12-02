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
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(device.name ?? "Unnamed")
                    .padding(.bottom, 4)
                
                switch device.status {
                case .connected:
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .accentColor(.green)
                        .font(.caption)
                case .error(let error):
                    Label("Error: \(error.localizedDescription)", systemImage: "exclamationmark.circle")
                        .accentColor(.nordicRed)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button("Disconnect") {
                print("Disconnect")
            }
            .accentColor(.nordicMiddleGrey)
            .buttonStyle(.borderedProminent)
        }
        .listRowSeparator(.hidden)
    }
}

