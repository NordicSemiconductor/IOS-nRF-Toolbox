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
    
    @State private var showSensorCalibration = false
    
    // MARK: view
    
    var body: some View {
        Section {
            RunningValuesGrid()
        }
        
        Section {
            Button("Sensor Calibration", systemImage: "lines.measurement.horizontal") {
                showSensorCalibration = true
            }
            .sheet(isPresented: $showSensorCalibration, content: {
                if let vm = environment.sensorCalibrationViewModel {
                    NavigationStack {
                        SensorCalibrationScreen(viewModel: vm)
                    }
                }
            })
            .accentColor(.nordicBlue)
            .centered()
        }
    }
}
