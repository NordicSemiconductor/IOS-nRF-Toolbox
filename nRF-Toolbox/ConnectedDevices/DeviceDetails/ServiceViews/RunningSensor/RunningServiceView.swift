//
//  RunningServiceView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library
import CoreBluetoothMock
import iOS_Common_Libraries

struct RunningServiceView: View {
    @ObservedObject var viewModel: RunningServiceHandler
    @State var showCalibration = false
    @State var waitingForCalibration = false
    @State private var availableLocations: [SensorLocation] = []
    
    var body: some View {
        List {
            Section("Measurement") {
                MeasurementView(
                    instantaneousSpeed: viewModel.instantaneousSpeed,
                    instantaneousCadence: viewModel.instantaneousCadence,
                    instantaneousStrideLength: viewModel.instantaneousStrideLength,
                    totalDistance: viewModel.totalDistance
                )
            }
            
            if viewModel.sensorLocationSupported {
                Section("Sensor Location") {
                    SensorLocationView(sensorLocation: viewModel.sensorLocationValue, readingSensorLocation: $viewModel.readingSersorLocation) {
                        Task {
                            try? await viewModel.readSensorLocation()
                        }
                    }
                    .padding()
                }
            }
            
            Section("Control") {
                Button("Calibrate Sensor") {
                    waitingForCalibration = true
                    Task {
                        defer {
                            waitingForCalibration = false 
                        }
                        do {
                            availableLocations = try await viewModel.requestSupportedSensorLocations()
                            showCalibration = true
                        } catch let e {
                            viewModel.presentError(e)
                        }
                    }
                }
                .disabled(waitingForCalibration)
                .sheet(isPresented: $showCalibration) {
                    NavigationStack {
                        CalibrateSensor(sensorLocations: availableLocations) {
                            
                        } updateData: {
                            
                        }
                    }
                }
            }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error) {
            Button("Cancel") {
                
            }
        }
    }
}

struct RunningServiceView_Previews: PreviewProvider {
    static var previews: some View {
        RunningServiceView(viewModel: RunningServiceHandlerPreview()! as RunningServiceHandler)
    }
}
