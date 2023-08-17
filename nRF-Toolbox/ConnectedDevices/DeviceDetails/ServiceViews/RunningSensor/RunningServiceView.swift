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
    @StateObject var settingsHud = HUDState()
    
    @State var showCalibration = false
    
    var body: some View {
        List {
            Section("Measurement") {
                ForEach([viewModel.instantaneousSpeed, viewModel.instantaneousCadence, viewModel.instantaneousStrideLength, viewModel.totalDistance], id: \.text) {
                    LabledValueView(someValue: $0)
                }
            }
            
            if let running = viewModel.runningOrWalking {
                Section("Running or Walking") {
                    if running {
                        Label("Running", systemImage: "figure.run")
                    } else {
                        Label("Walking", systemImage: "figure.walk")
                    }
                }
            }
            
            if viewModel.sensorLocationSupported {
                Section("Sensor Location") {
                    SensorLocationView(sensorLocation: viewModel.sensorLocationValue, readingSensorLocation: $viewModel.readingSersorLocation) {
                        Task {
                            try? await viewModel.updateSensorLocation()
                        }
                    }
                    .padding()
                }
            }
            
            if viewModel.scControlPointCh != nil {
                Section("Control") {
                    Button("Sensor Settings") {
                        showCalibration = true
                    }
                    .sheet(isPresented: $showCalibration) {
                        NavigationStack {
                            SensorSettings(viewModel: SensorSettings.ViewModel(handler: viewModel))
                                .environmentObject(settingsHud)
                                .hud(isPresented: $settingsHud.isPresented) {
                                    Label(settingsHud.title, systemImage: settingsHud.systemImage)
                                }
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
