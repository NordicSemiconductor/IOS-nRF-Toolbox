//
//  TemperatureView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - TemperatureView

struct TemperatureView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: TemperatureViewModel
    
    // MARK: Constants
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("E d MMM yyyy HH:mm:ss")
        return dateFormatter
    }()
    
    // MARK: view
    
    var body: some View {
        LabeledContent {
            Text(viewModel.measurement.temperatureFormattedString())
        } label: {
            Label("Measurement", systemImage: "thermometer.variable")
                .setAccent(Color.universalAccentColor)
        }
        
        LabeledContent {
            Text(viewModel.measurement.location.nilDescription)
        } label: {
            Label("Location", systemImage: "figure.dance")
                .setAccent(Color.universalAccentColor)
        }
        
        LabeledContent {
            if let timestamp = viewModel.measurement.timestamp {
                Text(Self.dateFormatter.string(from: timestamp))
            } else {
                Text("nil")
            }
        } label: {
            Label("Timestamp", systemImage: "stopwatch")
                .setAccent(Color.universalAccentColor)
        }
    }
}
