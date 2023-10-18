//
//  RSSIChartView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts

struct RSSIItem: Identifiable {
    let timeinterval: TimeInterval
    var id: TimeInterval { timeinterval }
    
    let value: Int
    
    var color: Color {
        value < 10 ? .yellow : .green
    }
}

@available(iOS 17.0, *)
struct RSSIChartView: View {
    let rssiValues: [RSSIItem]
    
    var body: some View {
        Chart(rssiValues) { r in
            PointMark(
                x: .value("time", r.timeinterval),
                y: .value("rssi", r.value)
            )
            .foregroundStyle(r.color)
        }
//        .chartScrollableAxes(.horizontal)
//        .chartXVisibleDomain(length: 200)
        .padding()
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        RSSIChartView(
            rssiValues: RSSIItem.preview
        )
    } else {
        Text("Not Available")
    }
}
