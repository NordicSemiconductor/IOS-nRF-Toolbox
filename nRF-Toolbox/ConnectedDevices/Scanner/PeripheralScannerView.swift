//
//  PeripheralScannerView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct PeripheralScannerView: View {
    @StateObject var viewModel: ViewModel
    
    fileprivate init(state: ViewModel.State, devices: [ViewModel.ScanResult] = []) {
        self._viewModel = StateObject(wrappedValue: ViewModel(state: state, devices: devices))
    }
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .disabled:
                disabled
            case .scanning:
                if viewModel.devices.isEmpty {
                    emptyResults
                } else {
                    deviceList
                }
            case .unsupported:
                unsupported
            }
        }
    }
    
    @ViewBuilder
    var unsupported: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "Bluetooth is Unavailable",
                secondaryText: "It looks like your device doesn't support bluetooth",
                systemName: "hand.thumbsdown"
            )
        )
    }
    
    @ViewBuilder
    var disabled: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "Bluetooth is Turned Off",
                secondaryText: "It looks like Bluetooth is turnd off. You can turn it on in Settings",
                systemName: "gear",
                buttonConfiguration: ContentUnavailableConfiguration.ButtonConfiguration(title: "Open Settings", action: {
                    
                })
            )
        )
    }
    
    @ViewBuilder
    var emptyResults: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "Scanning ...",
                systemName: "binoculars"
            )
        )
    }
    
    @ViewBuilder
    var deviceList: some View {
        List(viewModel.devices) { device in
            Text(device.name)
        }
    }
}

struct PeripheralScannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PeripheralScannerView(state: .scanning)
            PeripheralScannerView(state: .scanning, devices: [PeripheralScannerView.ViewModel.ScanResult(name: "Device 1", id: UUID())])
            PeripheralScannerView(state: .disabled)
            PeripheralScannerView(state: .unsupported)
        }
    }
}
