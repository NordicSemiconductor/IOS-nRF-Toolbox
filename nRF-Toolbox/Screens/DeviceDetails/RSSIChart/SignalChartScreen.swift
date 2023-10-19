//
//  SignalChartScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

private typealias Env = SignalChartScreen.ViewModel.Environment

struct SignalChartScreen: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        SignalChartView()
            .onFirstAppear {
                viewModel.readSignal()
            }
            .environmentObject(viewModel.environment)
    }
}

struct SignalChartView: View {
    @EnvironmentObject private var environment: Env
    
    var body: some View {
        Chart(environment.chartData) { data in
            data.pointMark
                .foregroundStyle(data.style)
        }
        .chartXScale()
        .padding()
    }
}

extension Env.ChartData {
    var pointMark: PointMark {
        PointMark(
            x: .value("Time", date),
            y: .value("Signal", signal)
        )
    }
    
    var style: Color {
        switch signal {
        case 5...: return Color.gray
        case (-60)...: return Color.green
        case (-75)...: return Color.yellow
        case (-90)...: return Color.orange
        default: return Color.red
        }
    }
}

#Preview {
    SignalChartView()
        .environmentObject(Env(chartData: ChartDataPreview.data))
}
