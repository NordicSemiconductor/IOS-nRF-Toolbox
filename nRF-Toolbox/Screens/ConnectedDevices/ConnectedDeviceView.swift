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
    
    // MARK: Init
    
    init(_ device: ConnectedDevicesViewModel.Device) {
        self.device = device
    }
    
    // MARK: view
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(device.name ?? "Unnamed")
                    .font(.title3)
                    .padding(.bottom, 4)
                
                switch device.status {
                case .busy, .connected:
                    EmptyView()
                case .error(let error):
                    Label("Error: \(error.localizedDescription)", systemImage: "exclamationmark.circle")
                        .accentColor(.nordicRed)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            switch device.status {
            case .busy:
                ProgressView()
                    .progressViewStyle(.circular)
            case .connected:
                Button("Disconnect") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        Task {
                            try await connectedDevicesViewModel.disconnectAndRemoveViewModel(device.id)
                        }
                    }
                }
                .accentColor(.nordicDarkGrey)
                .buttonStyle(.borderedProminent)
            case .error:
                EmptyView()
            }
        }
        .listRowSeparator(.hidden)
    }
}

