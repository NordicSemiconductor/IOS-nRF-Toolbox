//
//  CGMSView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 1/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct CGMSView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CGMSViewModel
    
    // MARK: view
    
    var body: some View {
        if let lastRecord = viewModel.records.last {
            Text("Latest Record: \(lastRecord)")
        }
        
        Text("Record Count: \(viewModel.records.count)")
        
        Button("Request All Records") {
            viewModel.requestAllRecords()
        }
        .foregroundStyle(Color.universalAccentColor)
        
        Button(viewModel.sessionStarted ? "Stop Session" : "Start Session") {
            viewModel.toggleSession()
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
