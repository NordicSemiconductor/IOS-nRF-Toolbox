//
//  HeartRateScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = HeartRateScreen.HeartRateViewModel.Environment

struct HeartRateScreen: View {

    @ObservedObject var viewModel: HeartRateViewModel

    var body: some View {
        HeartRateView()
            .environmentObject(viewModel.env)
            .task {
                viewModel.onConnect()
            }
    }
}

struct HeartRateView: View {
    @EnvironmentObject private var environment: Env
    
    var body: some View {
        if environment.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
        } else {
            HeartRateChart()
        }
    }
}

#Preview {
    HeartRateView()
        .environmentObject(Env())
}
