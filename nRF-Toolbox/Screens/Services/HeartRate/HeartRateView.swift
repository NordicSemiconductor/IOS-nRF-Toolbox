//
//  HeartRateView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Created by Dinesh Harjani on 5/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

// MARK: - HeartRateChart

struct HeartRateChart: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: DeviceScreen.HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Chart {
                ForEach(viewModel.data, id: \.date) {
                    LineMark(
                        x: .value("Date", $0.date),
                        y: .value("Heart Rate", $0.heartRate)
                    )
                    .foregroundStyle(.red)
                }
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: [viewModel.lowest, viewModel.highest],
                         range: .plotDimension(padding: 8))
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: viewModel.visibleDomain)
            .chartScrollPosition(x: $viewModel.scrolPosition)
            
            if let heartRate = viewModel.data.last?.heartRate {
                Label("\(heartRate) bpm", systemImage: "waveform.path.ecg")
                    .font(.title2.bold())
            }
        }
    }
}

// MARK: - HeartRateView

struct HeartRateView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: DeviceScreen.HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
        } else {
            HeartRateChart()
        }
    }
}
