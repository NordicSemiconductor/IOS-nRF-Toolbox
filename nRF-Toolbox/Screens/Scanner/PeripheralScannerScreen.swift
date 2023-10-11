//
//  PeripheralScannerScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct PeripheralScannerScreen: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PeripheralScannerView()
            .environmentObject(viewModel.environment)
    }
}

fileprivate typealias ViewModel = PeripheralScannerScreen.ViewModel
struct PeripheralScannerView: View {
    @EnvironmentObject private var environment: ViewModel.PreviewEnvironment
    
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
//        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: { })

        .navigationTitle("Scanner")
    }
}

#Preview {
    NavigationStack {
        PeripheralScannerView()
            .environmentObject(ViewModel.PreviewEnvironment(
                devices: [
                    PeripheralScannerScreen.ViewModel.ScanResult(name: "Device", rssi: -59, id: UUID(), services: []),
                    PeripheralScannerScreen.ViewModel.ScanResult(name: "Device", rssi: -69, id: UUID(), services: []),
                    PeripheralScannerScreen.ViewModel.ScanResult(name: "Device", rssi: -79, id: UUID(), services: []),
                ],
                state: .scanning))
    }
}

#Preview {
    PeripheralScannerView()
        .environmentObject(ViewModel.PreviewEnvironment(state: .scanning))
}

#Preview {
    PeripheralScannerView()
        .environmentObject(ViewModel.PreviewEnvironment())
}
