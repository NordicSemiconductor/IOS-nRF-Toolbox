//
//  RunningServiceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

fileprivate typealias Env = RunningServiceScreen.RunningServiceViewModel.Environment

struct RunningServiceScreen: View {
    typealias VM = RunningServiceScreen.RunningServiceViewModel
    
    @ObservedObject var viewModel: RunningServiceViewModel
    
    var body: some View {
        RunningServiceView()
            .environmentObject(viewModel.environment)
            .onFirstAppear {
                viewModel.onConnect()
            }
    }
}

struct RunningServiceView: View {
    
    @EnvironmentObject private var environment: Env
    
    @State private var showSensorCalibration = false
    
    var body: some View {
        List {
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
}

#Preview {
    NavigationStack {
        RunningServiceView()
            .environmentObject(
                Env(
                    rscFeature: .all,
                    instantaneousSpeed: Measurement<UnitSpeed>(value: 1, unit: .metersPerSecond),
                    instantaneousCadence: 2,
                    instantaneousStrideLength: Measurement<UnitLength>(value: 2, unit: .meters)
                )
            )
            .navigationTitle("Running")
    }
}
