//
//  RunningValuesGridItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct RunningValuesGridItem: View {
    let title: String
    let value: String
    let unit: String?
    
    init(title: String, value: String, unit: String?) {
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    init<U: Unit>(title: String, measurement: Measurement<U>, numberFormatter: NumberFormatter? = nil) {
        self.title = title
        
        let nf: NumberFormatter
        if let numberFormatter {
            nf = numberFormatter
        } else {
            nf = NumberFormatter()
            nf.maximumFractionDigits = 2
        }
        
        self.value = nf.string(from: NSNumber(floatLiteral: measurement.value)) ?? "-.-"
        self.unit = measurement.unit.symbol
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                unit.map { Text($0) }
            }
        }
    }
}

#Preview {
    List {
        Grid(alignment: .leading) {
            GridRow {
                RunningValuesGridItem(title: "speed", value: "12.0", unit: "mph")
                Spacer()
                RunningValuesGridItem(title: "total distance", measurement: Measurement<UnitLength>(value: 10.3, unit: .meters))
            }
            GridRow {
                RunningValuesGridItem(title: "total distance", measurement: Measurement<UnitLength>(value: 103, unit: .meters))
                Spacer()
                RunningValuesGridItem(title: "speed", value: "1", unit: "mph")
            }
        }
    }
}
