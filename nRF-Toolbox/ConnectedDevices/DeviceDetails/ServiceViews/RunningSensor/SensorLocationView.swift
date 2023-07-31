//
//  SensorLocationView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct SensorLocationView: View {
    let sensorLocation: SensorLocation
    @Binding var readingSensorLocation: Bool
    
    let readSensorLocation: () -> ()
    
    var body: some View {
        HStack {
            Label {
                Text(sensorLocation.description)
            } icon: {
                Image(systemName: "sensor.tag.radiowaves.forward")
            }

            Spacer()
            if !readingSensorLocation {
                Button(action: readSensorLocation) {
                    Image(systemName: "arrow.clockwise")
                }
#if os(macOS)
                .buttonStyle(.plain)
#endif
            } else {
                ProgressView()
            }
            
        }
    }
}

struct SensorLocationView_Previews: PreviewProvider {
    static var previews: some View {
        SensorLocationView(sensorLocation: .chainRing, readingSensorLocation: .constant(false)) {
            
        }
    }
}
