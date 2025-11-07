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
    
    @Binding var item: UARTSequenceItem
    
    private var value: Binding<Float> {
        Binding<Float>(
            get: {
                if case let .delay(delay) = item {
                    return Float(delay)
                }
                return 0
            },
            set: { newValue in
                if case .delay = item {
                    item = .delay(newValue)
                }
            }
        )
    }
    
    var body: some View {
        switch item {
        case .delay(let delayValue):
            Slider(value: value, in: 0...30, step: 1) {
                EmptyView()
            } minimumValueLabel: {
                Text("0 ms")
            } maximumValueLabel: {
                Text("200 ms")
            }
            .onChange(of: value.wrappedValue) {
                self.value.wrappedValue = value.wrappedValue
            }
            .doOnce {
                value.wrappedValue = delayValue
            }
        case .command(let preset):
            Text(preset.toString() ?? "N/A")
        }
    }
}
