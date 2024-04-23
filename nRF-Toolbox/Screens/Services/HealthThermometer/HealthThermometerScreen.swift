//
//  HealthThermometerScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

private typealias Env = HealthThermometerScreen.VM.Environment

struct HealthThermometerScreen: View {
    
    @ObservedObject var viewModel: VM
    
    var body: some View {
        HealthThermometerView()
            .environmentObject(viewModel.env)
            .task {
                viewModel.onConnect()
            }
    }
}

struct HealthThermometerView: View {
    @EnvironmentObject private var environment: Env
    let gradient = Gradient(colors: [.blue, .red])
    
    var body: some View {
        VStack {
            HStack {
                currentTemperature()
                VStack(alignment: .leading) {
                    
                    Text("Health Thermometer")
                        .foregroundStyle(.secondary)
                    Label {
                        //                Text("\(env.data.last!.heartRate) bpm")
                        Text("Temperature (C)")
                    } icon: {
                        Image(systemName: "medical.thermometer")
                            .tint(.blue)
                    }
                    .font(.title2.bold())
                    
                }
            }
            if #available(iOS 17, macOS 14, *) {
                chart()
            } else {
                Text("iOS 16")
            }
        }
        .padding()
        
        
    }
    
    @ViewBuilder
    func currentTemperature() -> some View {
        if let temp = environment.currentTemperature {
            Gauge(
                value: temp.value,
                in: 29...45,
                label: {
                    
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
    
    @ViewBuilder
    private func chart() -> some View {
        Chart {
            ForEach(environment.records, id: \.date) {
                LineMark(
                    x: .value("Date", $0.date),
                    y: .value("Temperature", $0.temperature.value)
                )
            }
            .foregroundStyle(
                .linearGradient(
                    colors: [.blue, .red],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .chartYScale(
            domain: [environment.min, environment.max]
        )
    }
}

#Preview {
    NavigationView(content: {
        HealthThermometerView()
            .environmentObject(
                Env.preview1
            )
            .navigationTitle("Health Thermometer")
    })
}
