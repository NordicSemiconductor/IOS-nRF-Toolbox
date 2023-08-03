//
//  MeasurementView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct MeasurementView: View {
    let instantaneousSpeed: SomeValue
    let instantaneousCadence: SomeValue
    let instantaneousStrideLength: SomeValue
    let totalDistance: SomeValue
    
    var body: some View {
        VStack(alignment: .leading) {
            SomeValueView(someValue: instantaneousSpeed)
            SomeValueView(someValue: instantaneousCadence)
            SomeValueView(someValue: instantaneousStrideLength)
            SomeValueView(someValue: totalDistance)
        }
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView(
            instantaneousSpeed: SomeValue(
                systemName: "figure.run",
                text: "Speed",
                value: "12 mph",
                isActive: true,
                color: .purple
            ),
            instantaneousCadence: SomeValue(
                systemName: "basketball",
                text: "Cadence",
                value: "12 mph",
                isActive: false,
                color: .cyan
            ),
            instantaneousStrideLength: SomeValue(
                systemName: "tennis.racket",
                text: "Stride Length",
                value: "12 mph",
                isActive: true,
                color: .nordicFall
            ),
            totalDistance: SomeValue(
                systemName: "flag.checkered",
                text: "Speed",
                value: "12 mph",
                isActive: true,
                color: .nordicBlueslate
            )
        )
    }
}
