//
//  RunningServiceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - RunningServiceView

struct RunningServiceView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var environment: RunningServiceViewModel.Environment
    
    // MARK: Properties
    
    private static let list = ListFormatter()
    
    @State private var showSensorCalibration = false
    
    // MARK: view
    
    var body: some View {
        RunningValuesGrid()
        
        if let featureList = Self.list.string(from: environment.features.toArray()) {
            Label(featureList, systemImage: "checkmark.square.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        if (environment.isSensorCalibrationAvailable == true) {
            Button("Sensor Calibration", systemImage: "lines.measurement.horizontal") {
                showSensorCalibration = true
            }
            .foregroundStyle(Color.universalAccentColor)
            .sheet(isPresented: $showSensorCalibration, content: {
                if let viewModel = environment.sensorCalibrationViewModel {
                    NavigationStack {
                        SensorCalibrationScreen()
                            .environmentObject(viewModel)
                    }
                }
            })
            .centered()
        }
    }
}
