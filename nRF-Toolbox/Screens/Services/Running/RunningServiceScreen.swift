//
//  RunningServiceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

fileprivate typealias VM = RunningServiceScreen.ViewModel.Environment

struct RunningServiceScreen: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RunningServiceView()
            .environmentObject(viewModel.environment)
            .onFirstAppear {
                await viewModel.enableDeviceCommunication()
            }
    }
}

struct RunningServiceView: View {
    @EnvironmentObject private var environment: VM
    
    var body: some View {
        List {
            Section {
                RunningValuesGrid()
            }
            Section {
                Button("Sensor Calibration") {
                    
                }
            }
        }
       
    }
}

#Preview {
    NavigationStack {
        RunningServiceView()
            .environmentObject(
                VM(
                    rscFeature: .all,
                    instantaneousSpeed: Measurement<UnitSpeed>(value: 1, unit: .metersPerSecond),
                    instantaneousCadence: 2,
                    instantaneousStrideLength: Measurement<UnitLength>(value: 2, unit: .meters)
                )
            )
            .navigationTitle("Running")
    }
}
