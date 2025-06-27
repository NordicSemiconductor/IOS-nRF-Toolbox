//
//  ScanResultList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

fileprivate typealias Env = PeripheralScannerScreen.PeripheralScannerViewModel.Environment
fileprivate typealias ScanResult = Env.ScanResult

// MARK: - ScanResultList

struct ScanResultList: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var environment: Env
    @Environment(\.dismiss) var dismiss
    
    // MARK: Properties
    
    @State private var selectedDevice: ScanResult.ID?
    
    // MARK: view
    
    var body: some View {
        List {
            Section {
                ForEach(environment.devices) { device in
                    Button {
                        Task {
                            await environment.connect(device)
                            dismiss()
                        }
                    } label: {
                        ScanResultItem(name: device.name, services: device.services,
                                       showProgress: environment.connectingDevice == device)
                    }
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
