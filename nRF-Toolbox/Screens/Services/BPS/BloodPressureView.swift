//
//  BloodPressureView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 3/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - BPSView

struct BloodPressureView: View {
    
    // MARK: EnvironmentObject
    
    @Environment(BloodPressureViewModel.self) private var viewModel: BloodPressureViewModel
    
    // MARK: view
    
    var body: some View {
        if let currentValue = viewModel.currentValue {
            BloodPressureGrid(currentValue)
        } else {
            NoContentView(title: "No Data", systemImage: "drop.fill", description: "No Blood Pressure Data Available. You may press Button 1 on your DevKit to generate some Data.")
                .alignmentGuide(.listRowSeparatorLeading) { d in
                    d[.leading]
                }
        }
        
        if (!viewModel.features.isEmpty) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Supported features:").padding(.bottom, 4)
                ForEach(viewModel.features.toArray(), id: \.bitwiseValue) { feature in
                    Label(feature.description, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}
 
// MARK: - BloodPressureGrid

struct BloodPressureGrid: View {
    
    // MARK: Static
    
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a, dd/MM/yyyy"
        return formatter
    }()
    
    // MARK: Private Properties
    
    private let measurement: BloodPressureMeasurement
    
    // MARK: init
    
    init(_ measurement: BloodPressureMeasurement) {
        self.measurement = measurement
    }
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        if measurement.status?.isEmpty == false {
            ForEach(measurement.status?.bitsetMembers() ?? [], id: \.bitwiseValue) { feature in
                Label(feature.description, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        
        if let date = measurement.date {
            LabeledContent {
                Text(Self.timestampFormatter.string(from: date))
            } label: {
                Label("Timestamp", systemImage: "stopwatch")
            }
            .labeledContentStyle(.accentedContent(
                accentColor: .universalAccentColor, lineLimit: 1
            )).alignmentGuide(.listRowSeparatorLeading) { d in
                d[.leading]
            }
        }
    }
    
    // MARK: attributes
    
    private var attributes: [RunningAttribute] {
        var items = [RunningAttribute]()
        
        let systolicKey = "Systolic"
        items.append(RunningAttribute(title: systolicKey, value: String(format: "%.1f", measurement.systolicPressure.value), unit: measurement.systolicPressure.unit.symbol))

        let diastolicKey = "Diastolic"
        items.append(RunningAttribute(title: diastolicKey, value: String(format: "%.1f", measurement.diastolicPressure.value), unit: measurement.diastolicPressure.unit.symbol))
        
        let meanArterialPressureKey = "Mean Arterial Pressure"
        items.append(RunningAttribute(title: meanArterialPressureKey, value: String(format: "%.1f", measurement.meanArterialPressure.value), unit: measurement.meanArterialPressure.unit.symbol))

        let heartRateKey = "Heart Rate"
        if let heartRate = measurement.pulseRate {
            items.append(RunningAttribute(title: heartRateKey, value: "\(heartRate)", unit: "BPM"))
        } else {
            items.append(RunningAttribute(title: heartRateKey, value: "N/A", unit: "BPM"))
        }
        
        return items
    }
}
