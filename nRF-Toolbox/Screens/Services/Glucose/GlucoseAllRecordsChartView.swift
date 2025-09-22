//
//  GlucoseAllRecordsChartView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 20/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts
import iOS_Common_Libraries

// MARK: - GlucoseAllRecordsChartView

struct GlucoseAllRecordsChartView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: GlucoseViewModel
    
    // MARK: Properties
    
    @State private var scrollPosition = 0
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(viewModel.allRecords.count) Records")
                .font(.title2.bold())
                .padding(.top, 8)
            
            HStack {
                DotView(.nordicRed)
                
                Text("Latest Value: \(viewModel.allRecords.last?.measurement.formatted() ?? "N/A")")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, -4)
            
            Chart {
                ForEach(viewModel.allRecords, id: \.sequenceNumber) { value in
                    LineMark(
                        x: .value("Sequence Number", value.sequenceNumber),
                        y: .value("Glucose Measurement", value.measurement.value)
                    )
                    .foregroundStyle(Color.nordicRed)
                    
                    PointMark(
                        x: .value("Sequence Number", value.sequenceNumber),
                        y: .value("Glucose Measurement", value.measurement.value)
                    )
                    .foregroundStyle(Color.nordicRed)
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
            .chartXVisibleDomain(length: 20)
            .chartScrollPosition(x: $scrollPosition)
            .padding(.top, 8)
        }
        
        NavigationLink("View All Records") {
            GlucoseListView(viewModel.allRecords)
                .environmentObject(viewModel)
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
