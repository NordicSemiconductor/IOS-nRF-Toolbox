//
//  TemperatureView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - TemperatureChart

struct TemperatureChart: View {
    
    // MARK: view
    
    var body: some View {
        Text("Chart")
    }
}

// MARK: - TemperatureView

struct TemperatureView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: TemperatureViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.data.isEmpty {
            NoContentView(title: "No Temperature Data", systemImage: "waveform.path.ecg.rectangle")
        } else {
            TemperatureChart()
        }
    }
}
