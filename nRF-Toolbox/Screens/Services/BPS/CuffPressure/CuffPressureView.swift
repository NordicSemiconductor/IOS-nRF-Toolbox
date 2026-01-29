//
//  CuffPressureView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - CuffPressureView

struct CuffPressureView: View {
    
    // MARK: EnvironmentObject
    
    @Environment(CuffPressureViewModel.self) private var viewModel: CuffPressureViewModel
    
    // MARK: view
    
    var body: some View {
        if let currentValue = viewModel.currentValue {
            CuffPressureGrid(currentValue)
        } else {
            NoContentView(title: "No Data", systemImage: "drop.fill", description: "No Intermediate Cuff Pressure Data Available.")
        }
    }
}

// MARK: - CuffPressureGrid

struct CuffPressureGrid: View {
    
    // MARK: Static
    
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a, dd/MM/yyyy"
        return formatter
    }()
    
    // MARK: Private Properties
    
    private let measurement: CuffPressureMeasurement
    
    // MARK: init
    
    init(_ measurement: CuffPressureMeasurement) {
        self.measurement = measurement
    }
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        if let date = measurement.timestamp {
            LabeledContent {
                Text(Self.timestampFormatter.string(from: date))
            } label: {
                Label("Timestamp", systemImage: "stopwatch")
            }
            .labeledContentStyle(.accentedContent(
                accentColor: .universalAccentColor, lineLimit: 1
            ))
        }
    }
    
    // MARK: attributes
    
    private var attributes: [RunningAttribute] {
        var items = [RunningAttribute]()
        
        let currentKey = "Current"
        items.append(RunningAttribute(title: currentKey, value: String(format: "%.1f", measurement.cuffPressure.value), unit: measurement.cuffPressure.unit.symbol))

        let heartRateKey = "Heart Rate"
        if let heartRate = measurement.pulseRate {
            items.append(RunningAttribute(title: heartRateKey, value: "\(heartRate)", unit: "BPM"))
        } else {
            items.append(RunningAttribute(title: heartRateKey, value: "N/A", unit: "BPM"))
        }
        
        return items
    }
}
