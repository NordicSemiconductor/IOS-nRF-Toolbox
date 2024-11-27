//
//  ConnectedDevicesView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - ConnectedDevicesScreen

struct ConnectedDevicesScreen: View {
    @EnvironmentObject var viewModel: ConnectedDevicesViewModel
    
    var body: some View {
            ConnectedDevicesView {
                NavigationStack {
                    PeripheralScannerScreen(centralManager: viewModel.centralManager)
#if os(macOS)
                        .frame(minWidth: 400, minHeight: 450)
#endif
                }
                .interactiveDismissDisabled()
            }
            .navigationTitle("Connected Devices")
            .environmentObject(viewModel.environment)
            .environmentObject(viewModel)
    }
}

// MARK: - ConnectedDevicesView

struct ConnectedDevicesView<ScannerScreen: View> : View {
    @EnvironmentObject var environment: ConnectedDevicesViewModel.Environment
    
    @State var selectedService: String?
    
    let scannerScreen: () -> ScannerScreen
    
    init(@ViewBuilder scannerScreen: @escaping () -> ScannerScreen) {
        self.scannerScreen = scannerScreen
    }
    
    var body: some View {
        VStack {
            if environment.connectedDevices.isEmpty {
                ConnectedDevicesScreen.InitialState()
                    .padding()
                    .environmentObject(environment)
            } else {
                ConnectedDeviceList()
                
                Button("Connect Another") {
                    environment.showScanner = true
                }
#if os(macOS)
                .padding()
#endif
            }
        }
        .sheet(isPresented: $environment.showScanner, content: scannerScreen)
    }
}
