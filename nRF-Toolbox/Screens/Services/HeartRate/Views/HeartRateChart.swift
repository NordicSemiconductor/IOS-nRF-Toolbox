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
    
    @EnvironmentObject private var viewModel: HeartRateScreen.HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Heart Rate Monitor")
                .foregroundStyle(.secondary)
            Label {
                Text("\(viewModel.data.last!.heartRate) bpm")
            } icon: {
                Image(systemName: "waveform.path.ecg")
            }
            .font(.title2.bold())
            
            if #available(iOS 17, macOS 14, *) {
                scalableChart()
            } else {
                chart
            }
        }
        .padding()
    }
    
    // MARK: scalableChart
    
    @available(macOS 14.0, *)
    @available(iOS 17.0, *)
    @ViewBuilder
    private func scalableChart() -> some View {
        chart
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: viewModel.visibleDomain)
            .chartScrollPosition(x: $viewModel.scrolPosition)
    }
    
    // MARK: chart
    
    @ViewBuilder
    private var chart: some View {
        Chart {
            ForEach(viewModel.data, id: \.date) {
                LineMark(
                    x: .value("Date", $0.date),
                    y: .value("HR", $0.heartRate)
                )
                .foregroundStyle(.red)
            }
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: [viewModel.lowest, viewModel.highest], range: .plotDimension(padding: 8))
    }
}
