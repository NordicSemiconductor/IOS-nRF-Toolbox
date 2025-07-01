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
import iOS_Common_Libraries

// MARK: - HeartRateChart

struct HeartRateChart: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Heart Rate")
                    .font(.title2.bold())
                
                Spacer()
                
                if #available(iOS 18.0, *) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.nordicRed)
                        .symbolEffect(.bounce.up, options: .repeat(.periodic(delay: 0.1)))
                } else {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.nordicRed)
                }
                
                Text("\(viewModel.data.last?.measurement.heartRateValue ?? 0) BPM")
                    .foregroundStyle(.secondary)
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
            
            if let lastMeasurement = viewModel.data.last {
                Label {
                    Text(lastMeasurement.measurement.sensorContact.description)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "hand.rays.fill")
                        .foregroundStyle(Color.nordicMiddleGrey)
                }
                
                Label {
                    Text("RR Intervals Received: \(lastMeasurement.measurement.intervals?.count ?? 0)")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "arrow.left.and.right.circle")
                        .foregroundStyle(Color.nordicMiddleGrey)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - HeartRateView

struct HeartRateView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
        } else {
            HeartRateChart()
        }
    }
}
