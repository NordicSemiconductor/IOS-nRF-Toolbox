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

struct RunningServiceView: View {
    @ObservedObject var viewModel: RunningServiceHandler
    
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
            
            viewModel.sensorLocationValue.map { location in
                Section("Sensor Location") {
                    SensorLocationView(sensorLocation: location, readingSensorLocation: $viewModel.readingSersorLocation) {
                        Task {
                            try? await viewModel.readSensorLocation()
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct RunningServiceView_Previews: PreviewProvider {
    static var previews: some View {
        RunningServiceView(viewModel: RunningServiceHandlerPreview()! as RunningServiceHandler)
    }
}
