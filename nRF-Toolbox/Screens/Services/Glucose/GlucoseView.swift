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
    
    // MARK: Properties
    
    enum ViewMode: RegisterValue, Hashable, Equatable, CustomStringConvertible, CaseIterable {
        case all, first, last
        
        var description: String {
            switch self {
            case .all:
                return "All Records"
            case .first:
                return "First Record"
            case .last:
                return "Last Record"
            }
        }
        
        var cgmOperator: CGMOperator {
            switch self {
            case .all:
                return .allRecords
            case .first:
                return .first
            case .last:
                return .last
            }
        }
    }
    
    @State private var viewMode: ViewMode = .all
    
    // MARK: view
    
    var body: some View {
        InlinePicker(title: "Mode", systemImage: "square.on.square", selectedValue: $viewMode) { newMode in
            Task {
                await viewModel.requestRecords(newMode.cgmOperator)
            }
        }
        .labeledContentStyle(.accentedContent)
        
        Button("Request") {
            Task {
                await viewModel.requestRecords(viewMode.cgmOperator)
            }
        }
        .tint(.universalAccentColor)
        .centered()
    }
}
