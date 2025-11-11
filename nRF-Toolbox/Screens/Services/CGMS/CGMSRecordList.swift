//
//  CGMSRecordList.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 8/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - CGMSRecordList

struct CGMSRecordList: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CGMSViewModel
    
    // MARK: view
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.records, id: \.timeOffset) { value in
                    GlucoseMeasurementView(sequenceNumber: value.timeOffset,
                                           measurement: value.measurement,
                                           dateString: value.toStringDate())
                }
                
                if viewModel.inFlightRequest != nil {
                    ProgressView()
                        .fixedCircularProgressView()
                        .centered()
                } else if viewModel.records.isEmpty {
                    NoContentView(title: "No Records", systemImage: "drop.fill", description: "No Glucose Measurements have been received yet.")
                }
            } header: {
                Text("")
            } footer: {
                Text("\(viewModel.records.count) Records")
                    .foregroundStyle(Color.nordicMiddleGrey)
                    .font(.caption)
            }
        }
        .navigationTitle("Glucose Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.requestRecords(.allRecords)
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(viewModel.inFlightRequest != nil)
            }
        }
    }
}
