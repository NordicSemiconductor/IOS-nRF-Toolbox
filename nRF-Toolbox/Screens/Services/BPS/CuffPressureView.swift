//
//  CuffPressureView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct CuffPressureView: View {
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CuffPressureViewModel
    
    // MARK: view
    
    var body: some View {
        Text("Hello")
//        if let currentValue = viewModel.currentValue {
//            BloodPressureGrid(currentValue)
//        } else {
//            NoContentView(title: "No Data", systemImage: "drop.fill", description: "No Blood Pressure Data Available. You may press Button 1 on your DevKit to generate some Data.")
//        }
//        
//        ForEach(viewModel.features.toArray(), id: \.bitwiseValue) { feature in
//            Label(feature.description, systemImage: "checkmark.circle.fill")
//                .font(.caption)
//                .foregroundStyle(Color.secondary)
//        }
    }
}
