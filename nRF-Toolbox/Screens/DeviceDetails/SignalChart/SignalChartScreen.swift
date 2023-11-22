//
//  SignalChartScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

private typealias Env = SignalChartScreen.SignalChartViewModel.Environment

struct SignalChartScreen: View {
    let viewModel: SignalChartViewModel
    
    var body: some View {
        SignalChartView()
            .padding()
            .onFirstAppear {
                viewModel.onConnect()
            }
            .environmentObject(viewModel.environment)
    }
}

struct SignalChartView: View {
    @EnvironmentObject private var environment: Env
    
    var body: some View {
        SignalChart()
    }
}

#Preview {
    SignalChartView()
        .environmentObject(Env(chartData: []))
}
