//
//  HeartRateChart.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

private typealias Env = HeartRateScreen.ViewModel.Environment

struct HeartRateChart: View {
    @EnvironmentObject private var env: Env
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Heart Rate Monitor")
                .foregroundStyle(.secondary)
            Label {
                Text("\(env.data.last!.heartRate) bpm")
            } icon: {
                Image(systemName: "waveform.path.ecg")
            }
            .font(.title2.bold())
            
            if #available(iOS 17, macOS 14, *) {
                scalableChart()
            } else {
                chart
            }
        }
        .padding()
    }
    
    @available(macOS 14.0, *)
    @available(iOS 17.0, *)
    @ViewBuilder
    private func scalableChart() -> some View {
        chart
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: env.visibleDomain)
            .chartScrollPosition(x: $env.scrolPosition)
    }
    
    @ViewBuilder
    private var chart: some View {
        Chart {
            ForEach(env.data, id: \.date) {
                LineMark(
                    x: .value("Date", $0.date),
                    y: .value("HR", $0.heartRate)
                )
                .foregroundStyle(.red)
            }
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: [env.lowest, env.highest], range: .plotDimension(padding: 8))
        
    }
}

#Preview {
    HeartRateChart()
        .environmentObject(Env(data: HeartRateMeasurementCharacteristic.mock))
}
