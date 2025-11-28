//
//  ScanResultList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - ScanResultList

struct ScanResultList: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: ConnectedDevicesViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: view
    
    var body: some View {
        List {
            Section {
                ForEach(Array(viewModel.devices.enumerated()), id: \.element.id) { index, device in
                    Button {
                        Task {
                            let result = await viewModel.connect(to: device)
                            dismiss() // Dismiss first before showing error.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                viewModel.onConnectionResult(result: result)
                            }
                        }
                    } label: {
                        ScanResultItem(name: device.name, services: device.services,
                                       showProgress: viewModel.connectingDevice == device)
                    }.accessibilityIdentifier("scanner_item_\(index)")
                }
                
                VStack {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        
                        Text("Scanning...")
                            .padding(.horizontal)
                    }
                    .padding(.top, 12)
                    
                    IndeterminateProgressView()
                        .accentColor(.universalAccentColor)
                }
            } footer: {
                Label("Tap a device to connect", systemImage: "hand.tap.fill")
            }
        }
        .listStyle(.insetGrouped)
    }
}
