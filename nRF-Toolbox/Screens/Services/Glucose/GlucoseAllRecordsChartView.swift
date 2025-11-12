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
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(viewModel.allRecords.count) Records")
                .font(.title2.bold())
                .padding(.top, 8)
            
            HStack {
                DotView(.nordicRed)
                
                Text("Latest Value: \(viewModel.allRecords.last?.measurement?.formatted() ?? "N/A")")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, -4)
            
            Chart {
                ForEach(viewModel.allRecords, id: \.sequenceNumber) { value in
                    LineMark(
                        x: .value("Sequence Number", value.sequenceNumber),
                        y: .value("Glucose Measurement", value.measurement?.value ?? 0.0)
                    )
                    .foregroundStyle(Color.nordicRed)
                    
                    PointMark(
                        x: .value("Sequence Number", value.sequenceNumber),
                        y: .value("Glucose Measurement", value.measurement?.value ?? 0.0)
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
            .chartXScale(domain: [-1, viewModel.maxX+5])
            .chartXVisibleDomain(length: 10)
            .chartScrollPosition(x: $viewModel.scrollPosition)
            .padding(.top, 8)
        }
        
        NavigationLink("View All Records") {
            GlucoseListView(viewModel.allRecords)
                .environmentObject(viewModel)
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
