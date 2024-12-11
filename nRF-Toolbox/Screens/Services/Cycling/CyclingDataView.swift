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
    
    // MARK: Static
    
    private static let speedFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 1)
    private static let distanceFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 2)
    
    @State private var wheelSizeInches = 29.0
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        Text("Wheel Size")
        
        Slider(value: $wheelSizeInches, in: 20...29, step: 1) {
            EmptyView()
        } minimumValueLabel: {
            Text("\(Measurement<UnitLength>(value: 20.0, unit: .inches).formatted())")
        } maximumValueLabel: {
            Text("\(Measurement<UnitLength>(value: 29.0, unit: .inches).formatted())")
        }
        .onChange(of: wheelSizeInches) {
            viewModel.wheelSize = Measurement<UnitLength>(value: wheelSizeInches, unit: .inches)
        }
        .listRowSeparator(.hidden)
        .accentColor(.nordicBlue)
        
        Text("Speed \(Self.speedFormatter.string(from: viewModel.speed))")
        
        Text("Distance \(Self.distanceFormatter.string(from: viewModel.travelDistance))")
    }
    
    // MARK: attributes
    
    private var attributes: [RunningAttribute] {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        
        var items = [RunningAttribute]()
        
        let speedKey = "Speed"
        items.append(RunningAttribute(title: speedKey, value: Self.speedFormatter.string(from: viewModel.speed), unit: viewModel.speed.unit.symbol))

        let cadenceKey = "Cadence"
        items.append(RunningAttribute(title: cadenceKey, value: "\(viewModel.cadence)", unit: "RPM"))
        
        let totalDistanceKey = "Total Distance"
        items.append(RunningAttribute(title: totalDistanceKey, value: String(format: "%.2f", viewModel.totalTravelDistance.value), unit: viewModel.totalTravelDistance.unit.symbol))
        
        let wheelKey = "Wheel Size"
        items.append(RunningAttribute(title: wheelKey, value: String(format: "%.1f", viewModel.wheelSize.value), unit: viewModel.wheelSize.unit.symbol))
        
        let gearKey = "Gear Ratio"
        items.append(RunningAttribute(title: gearKey, value: String(format: "%.2f", viewModel.gearRatio), unit: "⚙️"))
        
        return items
    }
}
