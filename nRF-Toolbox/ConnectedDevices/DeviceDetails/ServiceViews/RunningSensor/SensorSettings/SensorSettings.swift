//
//  SensorSettings.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 01/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import iOS_BLE_Library_Mock
import CoreBluetoothMock_Collection

struct SensorSettings: View {
    @StateObject var viewModel: ViewModel
    @EnvironmentObject var hudState: HUDState
    
    @State var showConfirmationAlert = false
    
    @State var resetDistanceDisabled = false
    @State var updateLocationDisabled = false
    @State var startCalibrationDisabled = false
    
    @Binding var displaySettings: Bool
    
    init(viewModel: ViewModel, displaySettings: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._displaySettings = displaySettings
    }
    
    var body: some View {
#if os(iOS)
        VStack(alignment: .leading) {
            settingsContent()
        }
#else
        List {
            settingsContent()
        }
#endif
        
    }
    
    @ViewBuilder
    func settingsContent() -> some View {
        VStack {
            if viewModel.supportedFeatures.contains(.totalDistanceMeasurement) || viewModel.supportedFeatures.contains(.multipleSensorLocation) || viewModel.supportedFeatures.contains(.sensorCalibrationProcedure) {
                settings
            } else {
                noContent
            }
        }
        .onAppear {
            Task {
                await viewModel.updateFeature()
                if viewModel.supportedFeatures.contains(.multipleSensorLocation) {
                    await viewModel.updateLocationSection()
                }
                viewModel.hudState = hudState
            }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {
            Button("Cancel") { }
        })
        .navigationTitle("Sensor Calibration")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    displaySettings = false
                }
            }
        }
    }
    
    @ViewBuilder
    var noContent: some View {
        NoContentView(title: "Settings Unavailable", systemImage: "sensor", description: "There's no settings to edit")
    }
    
    @ViewBuilder
    var settings: some View {
        Form {
            if viewModel.supportedFeatures.contains(.totalDistanceMeasurement) {
                
                Section("Reset Distance") {
                    Button("Reset Distance") {
                        showConfirmationAlert = true
                        resetDistanceDisabled = true
                    }
                    .disabled(resetDistanceDisabled)
                    .alert("Reset distance?", isPresented: $showConfirmationAlert) {
                        Button("Yes") {
                            Task {
                                await viewModel.resetDistance()
                                resetDistanceDisabled = false
                            }
                        }
                        Button("No") {
                            resetDistanceDisabled = false
                        }
                    } message: {
                        Text("The distance will be reset to 0")
                    }
                }
            }
            
            if viewModel.supportedFeatures.contains(.multipleSensorLocation) {
                Section("Sensor Location") {
                    Picker("Sensor Location", selection: $viewModel.selectedSensorLocation) {
                        ForEach(viewModel.availableLocation, id: \.rawValue) { location in
                            Text(location.description)
                                .disabled(!viewModel.availableLocation.contains(location))
                        }
                    }
                    .disabled(updateLocationDisabled)
                    
                    Button("Update Sensor Location") {
                        updateLocationDisabled = true
                        Task {
                            await viewModel.writeNewSensorLocation()
                            await viewModel.updateLocationSection()
                            updateLocationDisabled = false
                        }
                    }
                    .disabled(updateLocationDisabled || viewModel.currentSensorLocation == viewModel.selectedSensorLocation)
                }
            }
            
            if viewModel.supportedFeatures.contains(.sensorCalibrationProcedure) {
                Section("Calibration") {
                    Button("Start Calibration") {
                        startCalibrationDisabled = true
                        Task {
                            await viewModel.startCalibration()
                        }
                    }
                    .disabled(startCalibrationDisabled)
                }
            }
        }
    }
}

struct CalibrateSensor_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SensorSettings(viewModel: SensorSettings.MockViewModel(), displaySettings: .constant(false))
        }
    }
}
