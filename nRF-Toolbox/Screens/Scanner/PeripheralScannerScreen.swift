//
//  PeripheralScannerScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock

// MARK: - PeripheralScannerScreen

struct PeripheralScannerScreen: View {
    
    // MARK: Properties
    
    @EnvironmentObject private var viewModel: ConnectedDevicesViewModel
    
    // MARK: view
    
    var body: some View {
        ZStack {
            switch viewModel.scannerState {
            case .disabled:
                StateViews.Disabled()
            case .scanning:
                if viewModel.devices.isEmpty {
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
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.circlepath")
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .setupTranslucentBackground()
    }
}
