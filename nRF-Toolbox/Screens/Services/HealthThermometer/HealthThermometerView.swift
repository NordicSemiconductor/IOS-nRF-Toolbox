//
//  HealthThermometerView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - HealthThermometerView

struct HealthThermometerView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: HealthThermometerViewModel
    
    // MARK: Constants
    
    static let measurementFormatter = MeasurementFormatter()
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("E d MMM yyyy HH:mm:ss")
        return dateFormatter
    }()
    
    // MARK: view
    
    var body: some View {
        LabeledContent {
            if let temperature = viewModel.measurement?.temperature {
                Text(Self.measurementFormatter.string(from: temperature))
            } else {
                Text("N/A")
            }
        } label: {
            Label("Measurement", systemImage: "thermometer.variable")
                .setAccent(Color.universalAccentColor)
        }
        
        LabeledContent {
            if let location = viewModel.measurement?.location?.description {
                Text(location)
            } else {
                Text("N/A")
            }
        } label: {
            Label("Location", systemImage: "figure.dance")
                .setAccent(Color.universalAccentColor)
        }
        
        LabeledContent {
            if let timestamp = viewModel.measurement?.timestamp {
                Text(Self.dateFormatter.string(from: timestamp))
            } else {
                Text("N/A")
            }
        } label: {
            Label("Timestamp", systemImage: "stopwatch")
                .setAccent(Color.universalAccentColor)
        }
    }
}
