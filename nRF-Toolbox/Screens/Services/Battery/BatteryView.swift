//
//  BatteryView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 5/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - BatteryView

struct BatteryView: View {
    
    // MARK: EnvironmentObject
    
    @Environment(BatteryViewModel.self) private var viewModel: BatteryViewModel
    
    // MARK: view
    
    var body: some View {
        BatteryChart(data: viewModel.batteryLevelData, currentLevel: viewModel.currentBatteryLevel)
    }
}
