//
//  CalibrateSensor.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 01/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import iOS_Common_Libraries

struct CalibrateSensor: View {
    @State var newDistance: UInt? = nil
    @State var selectedSensorLocation: SensorLocation?
    
    let sensorLocations: [SensorLocation]
    
    let startCalibration: () -> ()
    let updateData: () -> ()
    
    var body: some View {
        Form {
            Section {
                TextField("New Distance", value: $newDistance, format: .number)
                
                Picker("Sensor Location", selection: $selectedSensorLocation) {
                    ForEach(SensorLocation.allCases, id: \.rawValue) { location in
                        Text(location.description)
                            .disabled(!sensorLocations.contains(location))
                    }
                }
            }
            
            Button("Start Calibration", action: startCalibration)
                .buttonStyle(NordicSecondary())
        }
        .navigationTitle("Sensor Calibration")
        .toolbar {
            ToolbarItem {
                Button("Update", action: updateData)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: updateData)
            }
        }
    }
}

struct CalibrateSensor_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CalibrateSensor(
                sensorLocations: [.other, .chest, .topOfShoe, .hip],
                startCalibration: {
                    
                }, updateData: {
                    
                }
            )
        }
    }
}
