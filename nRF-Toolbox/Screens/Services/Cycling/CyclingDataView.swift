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
    
    // Speed
    // Cadence
    // Distance
    // Total Distance
    // Gear Ratio
    
    private static let speedFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 1)
    private static let distanceFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 2)

    var body: some View {
        Text("Speed \(Self.speedFormatter.string(from: viewModel.speed))")
        
        Text("Cadence \(viewModel.cadence) RPM")
        
        Text("Distance \(Self.distanceFormatter.string(from: viewModel.travelDistance))")
        
        Text("Total Distance \(Self.distanceFormatter.string(from: viewModel.totalTravelDistance))")
        
        Text("Gear Ratio \(String(format: "%.2f", viewModel.gearRatio))")
        
        Text("Wheel Size \(viewModel.wheelSize)")
    }
}
