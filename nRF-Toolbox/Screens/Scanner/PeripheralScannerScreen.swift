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
    
    @EnvironmentObject private var viewModel: PeripheralScannerViewModel
    @EnvironmentObject private var environment: PeripheralScannerViewModel.Environment
    
    // MARK: view
    
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
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Refresh", systemImage: "arrow.circlepath") {
                    viewModel.refresh()
                }
            }
        }
        .onFirstAppear {
            viewModel.setupManager()
        }
    }
}
