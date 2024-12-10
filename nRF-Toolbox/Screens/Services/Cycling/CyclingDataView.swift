//
//  CyclingDataView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - CyclingDataView

struct CyclingDataView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var viewModel: CyclingServiceViewModel
    
    // MARK: view
    
    var body: some View {
        if let wheel = viewModel.data.crankRevolutionsAndTime {
            Text("Wheel \(wheel.revolution)")
            
            Text("Time \(wheel.time)")
        }
        
        if let crank = viewModel.data.crankRevolutionsAndTime {
            Text("Crank \(crank.revolution)")
            
            Text("Time \(crank.time)")
        }
    }
}
