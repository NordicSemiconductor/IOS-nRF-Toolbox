//
//  CGMSAllRecordsChartView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 25/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts
import iOS_Common_Libraries

// MARK: - CGMSAllRecordsChartView

struct CGMSAllRecordsChartView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CGMSViewModel
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(viewModel.records.count) Records")
                .font(.title2.bold())
            
            HStack {
                DotView(.nordicRed)
                
                Text("Current Value: \(viewModel.records.last?.measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided)) ?? "N/A")")
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(viewModel.records, id: \.timeOffset) { value in
                    LineMark(
                        x: .value("Sequence Number", value.timeOffset),
                        y: .value("Glucose Measurement", value.measurement.value)
                    )
                    .foregroundStyle(Color.nordicRed)
                    
                    PointMark(
                         x: .value("Sequence Number", value.timeOffset),
                         y: .value("Glucose Measurement", value.measurement.value)
                    ).foregroundStyle(Color.nordicRed)
                }
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: [viewModel.minY, viewModel.maxY],
                         range: .plotDimension(padding: 8))
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    
                    if let value = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(String(format: "%.1f", value))")
                        }
                    }
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXScale(domain: [0, max(20, Double(viewModel.records.count))])
            .chartScrollPosition(x: $viewModel.scrollPosition)
        }
        .padding(.vertical, 4)
        
        NavigationLink("View All Records") {
            CGMSRecordList()
                .environmentObject(viewModel)
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
