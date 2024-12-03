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
    
    // MARK: Environment
    
    @EnvironmentObject var connectedDevicesViewModel: ConnectedDevicesViewModel
    
    // MARK: Properties
    
    private let device: ConnectedDevicesViewModel.Device
    private let isSelected: Bool
    
    // MARK: Init
    
    init(_ device: ConnectedDevicesViewModel.Device, isSelected: Bool) {
        self.device = device
        self.isSelected = isSelected
    }
    
    // MARK: view
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(device.name ?? "Unnamed")
                    .font(.title3)
                    .padding(.bottom, 4)
                
                switch device.status {
                case .busy:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .connected:
                    Label("Connected", systemImage: "powerplug.fill")
                        .accentColor(.nordicBlue)
                        .font(.caption)
                case .error(let error):
                    Label("Error: \(error.localizedDescription)", systemImage: "exclamationmark.circle")
                        .accentColor(.nordicRed)
                        .font(.caption)
                }
                
                if isSelected {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .accentColor(.green)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button("Disconnect") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    Task {
                        try await connectedDevicesViewModel.disconnectAndRemoveViewModel(device.id)
                    }
                }
            }
            .accentColor(.nordicDarkGrey)
            .buttonStyle(.borderedProminent)
        }
        .listRowSeparator(.hidden)
    }
}

