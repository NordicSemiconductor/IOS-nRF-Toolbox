//
//  PeripheralScannerScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock

struct PeripheralScannerScreen: View {
    @StateObject var viewModel: PeripheralScannerViewModel
    
    init(centralManager: CentralManager) {
        self._viewModel = StateObject(wrappedValue: PeripheralScannerViewModel(centralManager: centralManager))
    }
    
    var body: some View {
        PeripheralScannerView()
            .onFirstAppear {
                viewModel.setupManager()
            }
            .environmentObject(viewModel.environment)
            
    }
}

fileprivate typealias ViewModel = PeripheralScannerScreen.PeripheralScannerViewModel
struct PeripheralScannerView: View {
    @EnvironmentObject private var environment: ViewModel.Environment
    
    var body: some View {
        VStack {
            switch environment.state {
            case .disabled:
                StateViews.Disabled()
            case .scanning:
                if environment.devices.isEmpty {
                    StateViews.EmptyResults()
                } else {
                    ScanResultList()
                }
            case .unsupported:
                StateViews.Unsupported()
            case .unauthorized:
                StateViews.Unauthorized()
            }
        }
        // TODO: Handle Error
//        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: { })
        .navigationTitle("Scanner")
    }
}

#Preview {
    NavigationStack {
        PeripheralScannerView()
            .environmentObject(ViewModel.Environment(
                devices: [
                    PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult(name: "Device", rssi: -59, id: UUID(), services: []),
                    PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult(name: "Device", rssi: -69, id: UUID(), services: []),
                    PeripheralScannerScreen.PeripheralScannerViewModel.ScanResult(name: "Device", rssi: -79, id: UUID(), services: []),
                ],
                state: .scanning))
    }
}

#Preview {
    PeripheralScannerView()
        .environmentObject(ViewModel.Environment(state: .scanning))
}

#Preview {
    PeripheralScannerView()
        .environmentObject(ViewModel.Environment())
}
