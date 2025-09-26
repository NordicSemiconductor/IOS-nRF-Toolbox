//
//  SensorCalibrationScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 21/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - SensorCalibrationScreen

struct SensorCalibrationScreen: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: SensorCalibrationViewModel
    
    // MARK: Private Properties
    
    @Environment(\.dismiss) var dismiss
    
    @State private var resetCumulativeValueDisabled = false
    @State private var startSensorCalibrationDisabled = false
    
    // MARK: view
    
    var body: some View {
        List {
            if viewModel.setCumulativeValueEnabled {
                onlyButtonSection(
                    header: "Reset Distance",
                    footer: "Reset total distance to 0",
                    buttonTitle: "Reset Cumulative Value",
                    action: {
                        Task {
                            await viewModel.resetCumulativeValue()
                        }
                    },
                    buttonDisabled: $resetCumulativeValueDisabled)
            }
            
            if viewModel.startSensorCalibrationEnabled {
                onlyButtonSection(
                    header: "Calibrate Sensor",
                    footer: "Initiate the sensor calibration procedure",
                    buttonTitle: "Start Sensor Calibration",
                    action: {
                        Task {
                            await viewModel.startSensorCalibration()
                        }
                    },
                    buttonDisabled: $startSensorCalibrationDisabled)
            }
            
            if viewModel.sensorLocationEnabled {
                section(
                    header: "Sensor Location",
                    footer: "Update the value of the Sensor Location",
                    buttonTitle: "Update Location",
                    buttonDisabled: $viewModel.updateSensorLocationDisabled) {
                        viewModel.updateSensorLocationDisabled = true
                        Task {
                            await viewModel.updateSensorLocation()
                        }
                    } content: {
                        // TECHNICAL DEBT: Blinking Picker. Not critical but annoying.
                        Picker("Location", selection: $viewModel.pickerSensorLocation) {
                            ForEach(viewModel.availableSensorLocations, id: \.rawValue) {
                                Text($0.description)
                                    .tag($0.rawValue)
                            }
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sensor Calibration")
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    dismiss()
                }
            }
        }
//        .errorAlert(error: $environment.alertError)
    }
    
    @ViewBuilder
    private func onlyButtonSection(header: String, footer: String, buttonTitle: String,
                                   action: @escaping () async -> (),
                                   buttonDisabled: Binding<Bool>) -> some View {
        section(header: header, footer: footer, buttonTitle: buttonTitle,
                buttonDisabled: buttonDisabled) {
            buttonDisabled.wrappedValue = true
                Task {
                    await action()
                }
                buttonDisabled.wrappedValue = false
            } content: {
                EmptyView()
            }
    }
    
    @ViewBuilder
    private func section<C: View>(header: String, footer: String, buttonTitle: String,
                                  buttonDisabled: Binding<Bool>, buttonAction: @escaping () -> (),
                                  content: () -> C) -> some View {
        Section {
            content()
            
            Button(buttonTitle, action: buttonAction)
                .tint(.nordicBlue)
                .disabled(buttonDisabled.wrappedValue)
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        }
    }
}
