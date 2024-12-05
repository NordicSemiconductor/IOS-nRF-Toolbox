//
//  HeartRateView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 5/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - HeartRateView

struct HeartRateView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: HeartRateScreen.HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
                .task {
                    await viewModel.prepare()
                }
        } else {
            HeartRateChart()
        }
    }
}
