//
//  BatteryChart.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 31/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock_Collection
import Charts

struct BatteryChart: View {
    let data: [ChartTimeData<Battery.Level>]
    
    var body: some View {
        Chart {
            ForEach(data, id: \.date) {
                BarMark(
                    x: .value("Date", $0.date),
                    y: .value("Battery Level", $0.value.level),
                    width: .automatic,
                    height: .automatic,
                    stacking: .standard
                )
                .foregroundStyle(batteryStyle(level: $0.value.level))
            }
        }
    }
    
    private func batteryStyle(level: UInt) -> Color {
        switch level {
        case 0..<10: .red
        case 10..<20: .yellow
        default: .green
        }
    }
}


#Preview {
    BatteryChart(
        data: Battery.preview
    )
}
