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
        
        var recordOperator: RecordOperator {
            switch self {
            case .all:
                return .allRecords
            case .first:
                return .firstRecord
            case .last:
                return .lastRecord
            }
        }
    }
    
    @State private var viewMode: ViewMode = .all
    
    // MARK: view
    
    var body: some View {
        switch viewMode {
        case .all:
            if viewModel.allRecords.hasItems {
                GlucoseAllRecordsChartView()
                    .environmentObject(viewModel)
            } else {
                noDataView()
            }
        case .first:
            if let firstRecord = viewModel.firstRecord {
                GlucoseMeasurementView(sequenceNumber: firstRecord.sequenceNumber,
                                       itemValue: firstRecord.measurement.description,
                                       dateString: firstRecord.toStringDate())
            } else {
                noDataView()
            }
        case .last:
            if let lastRecord = viewModel.lastRecord {
                GlucoseMeasurementView(sequenceNumber: lastRecord.sequenceNumber,
                                       itemValue: lastRecord.measurement.description,
                                       dateString: lastRecord.toStringDate())
            } else {
                noDataView()
            }
        }
        
        InlinePicker(title: "Mode", systemImage: "square.on.square", selectedValue: $viewMode) { newMode in
            viewModel.requestRecords(newMode.recordOperator)
        }
        .labeledContentStyle(.accentedContent)

        Button("Request") {
            viewModel.requestRecords(viewMode.recordOperator)
        }
        .tint(.universalAccentColor)
        .centered()
    }
    
    @ViewBuilder
    func noDataView() -> some View {
        NoContentView(title: "No Data", systemImage: "drop.fill", description: "No Glucose Level Data Available. You may press Button 3 on your DevKit to generate some Data.")
            .listRowSeparator(.hidden)
    }
}
