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
    
    // MARK: view
    
    var body: some View {
        PeripheralScannerView()
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
            .environmentObject(viewModel.environment)
    }
}

// MARK: - PeripheralScannerView

fileprivate typealias ViewModel = PeripheralScannerScreen.PeripheralScannerViewModel

struct PeripheralScannerView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var environment: ViewModel.Environment
    
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
        // TODO: Handle Error
//        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: { })
        .navigationTitle("Scanner")
    }
}
