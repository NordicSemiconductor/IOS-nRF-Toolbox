//
//  GlucoseListView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - GlucoseListView

struct GlucoseListView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: GlucoseViewModel
    
    // MARK: Private Properties
    
    private let measurements: [GlucoseMeasurement]
    
    // MARK: init
    
    init(_ measurements: [GlucoseMeasurement]) {
        self.measurements = measurements
    }
    
    // MARK: view
    
    var body: some View {
        List {
            Section {
                ForEach(measurements, id: \.sequenceNumber) { value in
                    GlucoseMeasurementView(sequenceNumber: value.sequenceNumber,
                                           measurement: value.measurement,
                                           sensor: value.sensorString(),
                                           location: value.locationString(),
                                           status: value.statusString(),
                                           dateString: value.toStringDate())
                }
                
                if viewModel.inFlightRequest != nil {
                    ProgressView()
                        .fixedCircularProgressView()
                        .centered()
                } else if measurements.isEmpty {
                    NoContentView(title: "No Records", systemImage: "drop.fill", description: "No Glucose Data has been received yet.")
                }
            } header: {
                Text("")
            } footer: {
                Text("\(measurements.count) Records")
                    .foregroundStyle(Color.nordicMiddleGrey)
                    .font(.caption)
            }
        }
        .navigationTitle("Glucose Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.requestRecords(.allRecords)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
    }
}
