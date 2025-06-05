//
//  BlinkyView.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 5/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//


import SwiftUI

// MARK: - BlinkyView

struct BlinkyView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: BlinkyViewModel
    
    // MARK: view
    
    var body: some View {
        Text("My name is Blinky")
//        LabeledContent {
//            Text(viewModel.measurement.temperatureFormattedString())
//        } label: {
//            Label("Measurement", systemImage: "thermometer.variable")
//                .setAccent(Color.universalAccentColor)
//        }
//        
//        LabeledContent {
//            Text(viewModel.measurement.location.nilDescription)
//        } label: {
//            Label("Location", systemImage: "figure.dance")
//                .setAccent(Color.universalAccentColor)
//        }
    }
}
