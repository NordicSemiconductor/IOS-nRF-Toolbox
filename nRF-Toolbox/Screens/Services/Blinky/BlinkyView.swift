//
//  BlinkyView.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 5/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//


import SwiftUI

// MARK: - BlinkyView

struct BlinkyView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: BlinkyViewModel
    
    // MARK: view
    
    var body: some View {
        LabeledContent {
            Toggle(viewModel.isLedOn ? "ON" : "OFF", isOn: $viewModel.isLedOn)
                .tint(.universalAccentColor)
        } label: {
            Label("LED State", systemImage: viewModel.isLedOn ? "lightbulb.max.fill" : "lightbulb")
                .setAccent(Color.universalAccentColor)
        }
        
        LabeledContent {
            Text(viewModel.isButtonPressed ? "Pressed" : "Released")
        } label: {
            Label("Button State", systemImage: viewModel.isButtonPressed ? "button.horizontal.fill" : "button.horizontal")
                .setAccent(Color.universalAccentColor)
        }
    }
}
