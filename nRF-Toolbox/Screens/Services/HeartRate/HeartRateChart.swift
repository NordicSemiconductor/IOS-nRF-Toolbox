//
//  HeartRateChart.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
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
            
            Label("\(viewModel.data.last!.heartRate) bpm", systemImage: "waveform.path.ecg")
                .font(.title2.bold())
        }
    }
}
