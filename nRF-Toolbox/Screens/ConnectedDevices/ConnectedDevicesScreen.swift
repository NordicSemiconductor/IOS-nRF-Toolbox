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
    
    var body: some View {
        PeripheralScannerScreen()
            .navigationTitle("Device Scanner")
            .environmentObject(viewModel.environment)
            .environmentObject(viewModel)
    }
}
