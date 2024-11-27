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
    
    @EnvironmentObject private var viewModel: ConnectedDevicesViewModel
    @EnvironmentObject private var scannerViewModel: PeripheralScannerScreen.PeripheralScannerViewModel
    
    var body: some View {
        ConnectedDevicesView {
            NavigationStack {
                PeripheralScannerScreen(centralManager: viewModel.centralManager)
#if os(macOS)
                    .frame(minWidth: 400, minHeight: 450)
#endif
            }
        }
//        VStack {
//            switch scannerViewModel.environment.state {
//            case .disabled:
//                StateViews.Disabled()
//            case .scanning:
//                if scannerViewModel.environment.devices.isEmpty {
//                    StateViews.EmptyResults()
//                } else {
//                    ScanResultList()
//                }
//            case .unsupported:
//                StateViews.Unsupported()
//            case .unauthorized:
//                StateViews.Unauthorized()
//            }
//        }
        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Dismiss", systemImage: "chevron.down") {
//                    dismiss()
//                }
//            }
            
            ToolbarItem(placement: .destructiveAction) {
                Button("Refresh", systemImage: "arrow.circlepath") {
                    scannerViewModel.refresh()
                }
            }
        }
        .onFirstAppear {
            scannerViewModel.setupManager()
        }
        .navigationTitle("Device Scanner")
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
#if os(macOS)
                .padding()
#endif
            }
        }
        .sheet(isPresented: $environment.showScanner, content: scannerScreen)
    }
}
