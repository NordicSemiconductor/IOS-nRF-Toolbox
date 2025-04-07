//
//  CGMSView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 1/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts
import iOS_Common_Libraries

struct CGMSView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CGMSViewModel
    
    // MARK: view
    
    var body: some View {
        Text("\(viewModel.records.count) Records")
            .font(.title2.bold())
        
        Text("Current Value: \(viewModel.records.last?.description ?? "N/A")")
            .foregroundStyle(.secondary)
        
        Chart {
            ForEach(viewModel.records, id: \.sequenceNumber) { value in
                LineMark(
                    x: .value("Sequence Number", value.sequenceNumber),
                    y: .value("Glucose Measurement", value.measurement.value)
                )
                .foregroundStyle(Color.nordicRed)
            }
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: [80.0, 100.0],
                     range: .plotDimension(padding: 8))
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 20)
        .chartScrollPosition(x: $viewModel.scrollPosition)
        
        Button(viewModel.sessionStarted ? "Stop Session" : "Start Session") {
            viewModel.toggleSession()
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
