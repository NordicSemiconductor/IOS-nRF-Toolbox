//
//  MeasurementView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct MeasurementView: View {
    let instantaneousSpeed: LabledValue
    let instantaneousCadence: LabledValue
    let instantaneousStrideLength: LabledValue
    let totalDistance: LabledValue
    
    var body: some View {
        VStack(alignment: .leading) {
            LabledValueView(someValue: instantaneousSpeed)
            LabledValueView(someValue: instantaneousCadence)
            LabledValueView(someValue: instantaneousStrideLength)
            LabledValueView(someValue: totalDistance)
        }
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView(
            instantaneousSpeed: LabledValue(
                systemName: "figure.run",
                text: "Speed",
                value: "12 mph",
                isActive: true,
                color: .purple
            ),
            instantaneousCadence: LabledValue(
                systemName: "basketball",
                text: "Cadence",
                value: "12 mph",
                isActive: false,
                color: .cyan
            ),
            instantaneousStrideLength: LabledValue(
                systemName: "tennis.racket",
                text: "Stride Length",
                value: "12 mph",
                isActive: true,
                color: .nordicFall
            ),
            totalDistance: LabledValue(
                systemName: "flag.checkered",
                text: "Speed",
                value: "12 mph",
                isActive: true,
                color: .nordicBlueslate
            )
        )
    }
}
