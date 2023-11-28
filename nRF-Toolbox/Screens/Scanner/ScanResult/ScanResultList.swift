//
//  ScanResultList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

fileprivate typealias Env = PeripheralScannerScreen.PeripheralScannerViewModel.Environment
fileprivate typealias ScanResult = PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult

struct ScanResultList: View {
    
    @EnvironmentObject private var environment: Env
    @Environment(\.dismiss) var dismiss
    @State private var selectedDevice: ScanResult.ID?
    
    @ViewBuilder
    private func deviceLabel(device: ScanResult) -> some View {
        HStack {
            ScanResultItem(name: device.name, rssi: device.rssi, services: device.services)
            Spacer()
            if environment.connectingDevice == device {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private func deviceView(device: ScanResult) -> some View {
        if #available(macOS 14.0, *) {
            deviceLabel(device: device)
        } else {
            Button {
                Task {
                    await environment.connect(device)
                    dismiss()
                }
            } label: {
                deviceLabel(device: device)
            }
            .buttonStyle(PlainButtonStyle())
#if os(macOS)
            Divider()
#endif
        }
    }
    
    @ViewBuilder
    private var devicesSection: some View {
        Section {
            ForEach(environment.devices) { device in
                deviceView(device: device)
            }
        } footer: {
            Text("Select the device to establish connection")
        }
    }
    
    var body: some View {
        if #available(macOS 14.0, iOS 17, *) {
            List(selection: $selectedDevice) {
                devicesSection
            }
            .onChange(of: selectedDevice) { oldValue, newValue in
                guard let deviceId = newValue else { return }
                guard let device = environment.devices.first(where: { $0.id == deviceId }) else { return }
                
                Task {
                    await environment.connect(device)
                    dismiss()
                }
            }
        } else {
            List {
                devicesSection
            }
        }
    }
}

#Preview {
    ScanResultList()
        .environmentObject(Env(devices: [
            PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult(name: "Device", rssi: -59, id: UUID(), services: []),
            PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult(name: "Device", rssi: -69, id: UUID(), services: []),
            PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult(name: "Device", rssi: -79, id: UUID(), services: []),
        ]))
}
