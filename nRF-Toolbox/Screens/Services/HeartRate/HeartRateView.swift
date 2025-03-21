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
            Text("Heart Rate")
                .font(.title2.bold())
            
            Label {
                Text("Current Value: \(viewModel.data.last?.measurement.heartRateValue ?? 0) BPM")
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "heart.fill")
                    .foregroundColor(.nordicRed)
            }
            
            Chart {
                ForEach(viewModel.data, id: \.date) { value in
                    LineMark(
                        x: .value("Date", value.date),
                        y: .value("Heart Rate", value.measurement.heartRateValue)
                    )
                    .foregroundStyle(Color.nordicRed)
                }
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: [viewModel.lowest, viewModel.highest],
                         range: .plotDimension(padding: 8))
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: viewModel.visibleDomain)
            .chartScrollPosition(x: $viewModel.scrollPosition)
            
            Label {
                Text("RR Intervals Received: \(viewModel.data.last?.measurement.intervals?.count ?? 0)")
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.nordicMiddleGrey)
            }
        }
        .padding(.vertical, 4)
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
