//
//  SignalChartView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

private typealias Env = SignalChartViewModel.Environment

// MARK: - ChartData

private extension Env.ChartData {
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

// MARK: - SignalChart

struct SignalChart: View {
    @EnvironmentObject private var environment: Env 
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("RSSI")
                .font(.title2.bold())
            
            Text("Updated once per second")
                .foregroundStyle(.secondary)
                .font(.caption)
            
            if #available(iOS 17, macOS 14, *) {
                scalableChart()
            } else {
                pureChart()
            }
        }
        .padding(.vertical)
    }
    
    @available(macOS 14.0, *)
    @available(iOS 17.0, *)
    @ViewBuilder
    private func scalableChart() -> some View {
        pureChart()
            .chartScrollableAxes(.horizontal)
            .chartXScale(domain: [environment.minDate, environment.maxDate], range: .plotDimension(padding: 8))
            .chartXVisibleDomain(length: SignalChartViewModel.Environment.visibleDomain)
            .chartScrollPosition(x: $environment.scrollPosition)
    }
    
    @ViewBuilder
    private func pureChart() -> some View {
        Chart(environment.chartData) { data in
            data.pointMark
                .foregroundStyle(data.style)
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: [environment.lowest, environment.highest], range: .plotDimension(padding: 8))
    }
}
