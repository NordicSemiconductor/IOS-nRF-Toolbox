//
//  CGMSView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 1/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - CGMSView

struct CGMSView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CGMSViewModel
    
    // MARK: Properties
    
    @State private var viewMode: GlucoseView.ViewMode = .all
    
    // MARK: view
    
    var body: some View {
        switch viewMode {
        case .all:
            if viewModel.records.hasItems {
                CGMSAllRecordsChartView()
            } else {
                noDataView()
            }
        case .first:
//            if let firstRecord = viewModel.firstRecord {
//                GlucoseMeasurementView(sequenceNumber: firstRecord.sequenceNumber,
//                                       measurement: firstRecord.measurement,
//                                       dateString: firstRecord.toStringDate())
//            } else {
//                noDataView()
//            }
            noDataView()
        case .last:
//            if let lastRecord = viewModel.lastRecord {
//                GlucoseMeasurementView(sequenceNumber: lastRecord.sequenceNumber,
//                                       measurement: lastRecord.measurement,
//                                       dateString: lastRecord.toStringDate())
//            } else {
//                noDataView()
//            }
            noDataView()
        }
        
        InlinePicker(title: "Mode", systemImage: "square.on.square", selectedValue: $viewMode) { newMode in
            Task {
                await viewModel.requestRecords(newMode.recordOperator)
            }
        }
        .labeledContentStyle(.accentedContent)
    }
    
    @ViewBuilder
    func noDataView() -> some View {
        NoContentView(title: "No Data", systemImage: "drop.fill", description: "No Continuous Glucose Measurement Data Available.")
            .listRowSeparator(.hidden)
    }
}
