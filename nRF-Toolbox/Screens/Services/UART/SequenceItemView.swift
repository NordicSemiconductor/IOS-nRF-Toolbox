//
//  SequenceItemView.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 07/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - SequenceItemView

struct SequenceItemView : View {
    
    let item: UARTSequenceItem
    @State var value: Float
    
    init(item: UARTSequenceItem) {
        self.item = item
        if case let .delay(delay) = item {
            self.value = Float(delay)
        } else {
            self.value = 0
        }
    }
    
    var body: some View {
        switch item {
        case .delay:
            Slider(value: $value, in: 0...30, step: 1) {
                EmptyView()
            } minimumValueLabel: {
                Text("0 ms")
            } maximumValueLabel: {
                Text("200 ms")
            }
            .onChange(of: value) {
                self.value = value
            }
        case .command(let preset):
            Text(preset.toString() ?? "N/A")
        }
    }
}
