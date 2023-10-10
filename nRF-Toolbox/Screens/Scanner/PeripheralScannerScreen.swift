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
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        
        EmptyView()
    }
}

struct PeripheralScannerView: View {
    typealias ViewModel = PeripheralScannerScreen.ViewModel
    @EnvironmentObject var environment: ViewModel.PreviewEnvironment
    
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
                        .environmentObject(environment)
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
    
    @ViewBuilder
    var deviceList: some View {
        
    }
}

#if DEBUG
fileprivate class MockVM: PeripheralScannerScreen.ViewModel {
    override init(bluetoothManager: CentralManagerHelper = CentralManagerHelper.shared, state: PeripheralScannerScreen.ViewModel.State = .scanning, devices: [PeripheralScannerScreen.ViewModel.ScanResult] = []) {
        
    }
}

struct PeripheralScannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PeripheralScannerScreen(state: .scanning)
            PeripheralScannerScreen(state: .disabled)
            PeripheralScannerScreen(state: .unsupported)
            PeripheralScannerScreen(state: .unauthorized)
        }
    }
}
#endif
