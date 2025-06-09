//
//  GlucoseView.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 6/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts
import iOS_Common_Libraries

// MARK: - GlucoseView

struct GlucoseView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: GlucoseViewModel
    
    // MARK: view
    
    var body: some View {
        Button("All") {
            Task {
                await viewModel.requestRecords(.allRecords)
            }
        }
        
        Button("First") {
            Task {
                await viewModel.requestRecords(.first)
            }
        }
        
        Button("Last") {
            Task {
                await viewModel.requestRecords(.last)
            }
        }
    }
}
