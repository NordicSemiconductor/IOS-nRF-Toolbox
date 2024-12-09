//
//  RunningServiceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

fileprivate typealias VM = RunningServiceScreen.RunningServiceViewModel.Environment

// MARK: - RunningServiceScreen

struct RunningServiceScreen: View {
    @ObservedObject var viewModel: RunningServiceViewModel
    
    var body: some View {
        RunningServiceView()
            .environmentObject(viewModel.environment)
    }
}

// MARK: - RunningServiceView

struct RunningServiceView: View {
    @EnvironmentObject private var environment: VM
    
    @State private var showSensorCalibration = false
    
    var body: some View {
        Section {
            RunningValuesGrid()
        }
        
        Section {
            Button("Sensor Calibration") {
                showSensorCalibration = true
            }
            .sheet(isPresented: $showSensorCalibration, content: {
                if let vm = environment.sensorCalibrationViewModel() {
                    NavigationStack {
                        SensorCalibrationScreen(viewModel: vm)
                    }
                }
            })
        }
    }
}
