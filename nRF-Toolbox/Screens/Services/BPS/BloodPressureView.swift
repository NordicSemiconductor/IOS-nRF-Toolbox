//
//  BloodPressureView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 3/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - BPSView

struct BloodPressureView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: BloodPressureViewModel
    
    // MARK: view
    
    var body: some View {
        if let currentValue = viewModel.currentValue {
            Text("BPS")
        } else {
            NoContentView(title: "No Data", systemImage: "drop.fill", description: "No Blood Pressure Data Available. You may press Button 1 on your DevKit to generate some Data.")
        }
    }
}
