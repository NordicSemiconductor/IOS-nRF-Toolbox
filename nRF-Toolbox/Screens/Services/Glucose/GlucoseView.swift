//
//  GlucoseView.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 6/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts
import iOS_Common_Libraries

// MARK: - GlucoseView

struct GlucoseView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: GlucoseViewModel
    
    // MARK: Properties
    
    enum ViewMode: RegisterValue, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case all, first, last
        
        var description: String {
            switch self {
            case .all:
                return "All Records"
            case .first:
                return "First Record"
            case .last:
                return "Last Record"
            }
        }
        
        var cgmOperator: CGMOperator {
            switch self {
            case .all:
                return .allRecords
            case .first:
                return .first
            case .last:
                return .last
            }
        }
    }
    
    @State private var scrollPosition = 0
    @State private var viewMode: ViewMode = .all
    
    // MARK: view
    
    var body: some View {
        switch viewMode {
        case .all:
            Chart {
                ForEach(viewModel.allRecords, id: \.sequenceNumber) { value in
                    LineMark(
                        x: .value("Sequence Number", value.sequenceNumber),
                        y: .value("Glucose Measurement", value.measurement.value)
                    )
                    .foregroundStyle(Color.nordicRed)
                }
                .interpolationMethod(.catmullRom)
            }
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
            .padding(.top, 24)
            
            NavigationLink("View All Records") {
                GlucoseListView(viewModel.allRecords)
                    .environmentObject(viewModel)
            }
            .foregroundStyle(Color.universalAccentColor)
        case .first:
            if let firstRecord = viewModel.firstRecord {
                GlucoseMeasurementView(sequenceNumber: firstRecord.sequenceNumber,
                                       itemValue: firstRecord.measurement.description,
                                       dateString: firstRecord.toStringDate())
            } else {
                EmptyView()
            }
        case .last:
            if let lastRecord = viewModel.lastRecord {
                GlucoseMeasurementView(sequenceNumber: lastRecord.sequenceNumber,
                                       itemValue: lastRecord.measurement.description,
                                       dateString: lastRecord.toStringDate())
            } else {
                EmptyView()
            }
        }
        
        InlinePicker(title: "Mode", systemImage: "square.on.square", selectedValue: $viewMode)
            .labeledContentStyle(.accentedContent)
        
        Button("Request") {
            viewModel.requestRecords(viewMode.cgmOperator)
        }
        .tint(.universalAccentColor)
        .centered()
    }
}
