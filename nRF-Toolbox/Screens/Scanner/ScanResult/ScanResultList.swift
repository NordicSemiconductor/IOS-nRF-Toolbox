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
fileprivate typealias ScanResult = PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult

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
                        ScanDeviceView(device)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    
                    Text("Scanning...")
                }
                .centered()
                
                IndeterminateProgressView()
                    .accentColor(.universalAccentColor)
                    .padding(.leading, 6)
                    .listRowSeparator(.hidden)
            }
            
            Section {
                Label("Tap a device to connect", systemImage: "hand.tap.fill")
                    .listRowBackground(Color.clear)
                    .centered()
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - ScanDeviceView

struct ScanDeviceView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var environment: Env
    
    // MARK: Properties
    
    private let device: ScanResult
    
    // MARK: Init
    
    fileprivate init(_ device: ScanResult) {
        self.device = device
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            if environment.connectingDevice == device {
                ProgressView()
            }
            
            ScanResultItem(name: device.name, rssi: device.rssi, services: device.services)
        }
    }
}
