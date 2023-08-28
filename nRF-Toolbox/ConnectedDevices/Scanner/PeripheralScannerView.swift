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
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = ViewModel()
    
    init() {}
   
    #if DEBUG
    fileprivate init(state: ViewModel.State, devices: [ViewModel.ScanResult] = []) {
        self._viewModel = StateObject(wrappedValue: MockVM(state: state, devices: devices))
    }
    #endif
    
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
            case .unauthorized:
                unauthorized
            }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: { })

        .navigationTitle("Scanner")
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
        .padding()
    }
    
    @ViewBuilder
    var unauthorized: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "No Permission Granted",
                secondaryText: "Bluetooth is not authorized. Open settings and give access the application to use Bluetooth.",
                systemName: "xmark.seal"
            ),
            actions: {
                Button("Open Settings") {
                    // TODO: Open Settings
                }
                .buttonStyle(NordicSecondary())
            }
        )
        .padding()
    }
    
    @ViewBuilder
    var disabled: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "Bluetooth is Turned Off",
                secondaryText: "It looks like Bluetooth is turnd off. You can turn it on in Settings",
                systemName: "gear"
            ),
            actions: {
                Button("Open Settings") {
                    // TODO: Open Settings
                }
                .buttonStyle(NordicSecondary())
            }
        )
        .padding()
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
        List{
            Section {
                ForEach(viewModel.devices) { device in
                    VStack {
                        Button {
                            Task {
                                await viewModel.tryToConnect(device: device) {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                ScanResultItem(
                                    name: device.name,
                                    rssi: device.rssi,
                                    services: device.knownServices,
                                    otherServices: device.services.count - device.knownServices.count
                                )
                                Spacer()
                                if viewModel.connectingDevice == device {
                                    ProgressView()
                                } else {
                                    Button {
                                        // TODO: Open info screen
                                    } label: {
                                        Image(systemName: "info.circle")
                                    }
                                }
                            }
                        }
                        #if os(macOS)
                        Divider()
                        #endif
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } footer: {
                Text("Select the device to establish connection or press 􀅴 to open detailed information")
            }

        }
    }
}

#if DEBUG
fileprivate class MockVM: PeripheralScannerView.ViewModel {
    override init(bluetoothManager: CentralManagerHelper = CentralManagerHelper.shared, state: PeripheralScannerView.ViewModel.State = .scanning, devices: [PeripheralScannerView.ViewModel.ScanResult] = []) {
        
    }
}

struct PeripheralScannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PeripheralScannerView(state: .scanning)
            PeripheralScannerView(state: .disabled)
            PeripheralScannerView(state: .unsupported)
            PeripheralScannerView(state: .unauthorized)
        }
    }
}
#endif
