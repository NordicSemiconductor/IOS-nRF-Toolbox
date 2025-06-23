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
    
    private static let minWheelSize = Measurement<UnitLength>(value: 20.0, unit: .inches)
    private static let maxWheelSize = Measurement<UnitLength>(value: 29.0, unit: .inches)
    
    // MARK: Properties
    
    @State private var wheelSizeInches = 29.0
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        Text("Wheel Size")
            .font(.title3)
            .bold()
        
        Slider(value: $wheelSizeInches, in: Self.minWheelSize.value...Self.maxWheelSize.value,
               step: 1) {
            EmptyView()
        } minimumValueLabel: {
            Text(Self.minWheelSize, format: .measurement(width: .abbreviated, usage: .asProvided))
        } maximumValueLabel: {
            Text(Self.maxWheelSize, format: .measurement(width: .abbreviated, usage: .asProvided))
        }
        .onChange(of: wheelSizeInches) {
            viewModel.wheelSize = Measurement<UnitLength>(value: wheelSizeInches, unit: .inches)
        }
        .listRowSeparator(.hidden)
        .accentColor(.nordicBlue)
    }
    
    // MARK: attributes
    
    private var attributes: [RunningAttribute] {
        var items = [RunningAttribute]()
        
        let speedKey = "Speed"
        items.append(RunningAttribute(title: speedKey, value: String(format: "%.2f", viewModel.speed.value), unit: viewModel.speed.unit.symbol))

        let cadenceKey = "Cadence"
        items.append(RunningAttribute(title: cadenceKey, value: "\(viewModel.cadence)", unit: "RPM"))
        
        let distanceKey = "Distance"
        items.append(RunningAttribute(title: distanceKey, value: String(format: "%.2f", viewModel.travelDistance.value), unit: viewModel.travelDistance.unit.symbol))
        
        let totalDistanceKey = "Total Distance"
        items.append(RunningAttribute(title: totalDistanceKey, value: String(format: "%.2f", viewModel.totalTravelDistance.value), unit: viewModel.totalTravelDistance.unit.symbol))
        
        let wheelKey = "Wheel Size"
        items.append(RunningAttribute(title: wheelKey, value: String(format: "%.1f", viewModel.wheelSize.value), unit: viewModel.wheelSize.unit.symbol))
        
        let gearKey = "Gear Ratio"
        items.append(RunningAttribute(title: gearKey, value: String(format: "%.2f", viewModel.gearRatio), unit: "⚙️"))
        
        return items
    }
}
