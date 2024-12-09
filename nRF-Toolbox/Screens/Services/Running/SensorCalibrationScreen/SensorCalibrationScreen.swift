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
    @ObservedObject private var viewModel: SensorCalibrationViewModel
    
    init(viewModel: SensorCalibrationViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        SensorCalibrationView()
            .navigationTitle("Sensor Calibration")
            .environmentObject(viewModel.environment)
    }
}

// MARK: - SensorCalibrationView

private typealias Env = SensorCalibrationViewModel.Environment

struct SensorCalibrationView: View {
    @EnvironmentObject private var environment: Env
    
    @State private var resetCumulativeValueDisabled = false
    @State private var startSensorCalibrationDisabled = false
    
    var body: some View {
        List {
            if environment.setCumulativeValueEnabled {
                onlyButtonSection(
                    header: "Reset Distance",
                    footer: "Reset total distance to 0",
                    buttonTitle: "Reset Cumulative Value",
                    action: environment.resetCumulativeValue,
                    buttonDisabled: $resetCumulativeValueDisabled)
            }
            
            if environment.startSensorCalibrationEnabled {
                onlyButtonSection(
                    header: "Calibrate Sensor",
                    footer: "Initiate the sensor calibration procedure",
                    buttonTitle: "Start Sensor Calibration",
                    action: environment.startSensorCalibration,
                    buttonDisabled: $startSensorCalibrationDisabled)
            }
            
            if environment.sensorLocationEnabled {
                section(
                    header: "Sensor Location",
                    footer: "Update the value of the Sensor Location",
                    buttonTitle: "Update Location",
                    buttonDisabled: $environment.updateSensorLocationDisabled) {
                        environment.updateSensorLocationDisabled = true
                        Task {
                            await environment.updateSensorLocation()
                        }
                    } content: {
                        // TECHNICAL DEBT: Blinking Picker. Not critical but annoying.
                        Picker("Location", selection: $environment.pickerSensorLocation) {
                            ForEach(environment.availableSensorLocations, id: \.rawValue) {
                                Text($0.description)
                                    .tag($0.rawValue)
                            }
                        }
                    }
            }
        }
        .errorAlert(error: $environment.alertError)
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
                .disabled(buttonDisabled.wrappedValue)
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        }
    }
}
