//
//  HealthThermometerScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = HealthThermometerScreen.VM.Environment

struct HealthThermometerScreen: View {

    @ObservedObject var viewModel: VM

    var body: some View {
        HealthThermometerView()
            .environmentObject(viewModel.env)
    }
}

struct HealthThermometerView: View {
    @EnvironmentObject private var environment: Env
    let gradient = Gradient(colors: [.blue, .red])

    var body: some View {
        if let temp = environment.currentTemperature {
            Gauge(
                value: temp.value,
                in: 29...45,
                label: {
                    Image(systemName: "medical.thermometer")
                        .tint(.blue)
                },
                currentValueLabel: {
                    Text(MeasurementFormatter().string(from: temp))
                }
            )
            .gaugeStyle(AccessoryCircularGaugeStyle())
            .tint(gradient)
            .padding()
        } else {
            Text("--")
        }
    }
}

#Preview {
    HealthThermometerView()
        .environmentObject(Env(
            currentTemperature: Measurement(value: 36.6, unit: .celsius)
        ))
}
