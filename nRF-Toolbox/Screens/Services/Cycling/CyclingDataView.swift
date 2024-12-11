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
    
    // MARK: view
    
    var body: some View {
        NumberedColumnGrid(columns: 2, data: attributes) { item in
            RunningValuesGridItem(title: item.title, value: item.value, unit: item.unit)
        }
        
        Text("Speed \(Self.speedFormatter.string(from: viewModel.speed))")
        
        Text("Distance \(Self.distanceFormatter.string(from: viewModel.travelDistance))")
    }
    
    // MARK: attributes
    
    private var attributes: [RunningAttribute] {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        
        var items = [RunningAttribute]()
        
        let speedKey = "Speed"
        items.append(RunningAttribute(title: speedKey, value: Self.speedFormatter.string(from: viewModel.speed), unit: nil))

        let cadenceKey = "Cadence"
        items.append(RunningAttribute(title: cadenceKey, value: "\(viewModel.cadence)", unit: "RPM"))
        
        let totalDistanceKey = "Total Distance"
        items.append(RunningAttribute(title: totalDistanceKey, value: Self.distanceFormatter.string(from: viewModel.totalTravelDistance), unit: nil))
        
        let wheelKey = "Wheel Size"
        items.append(RunningAttribute(title: wheelKey, value: String(format: "%.1f", viewModel.wheelSize.value), unit: viewModel.wheelSize.unit.symbol))
        
        let gearKey = "Gear Ratio"
        items.append(RunningAttribute(title: gearKey, value: String(format: "%.2f", viewModel.gearRatio), unit: "⚙️"))
        
//
//        if environment.rscFeature.contains(.instantaneousStrideLengthMeasurement) {
//            let strideLengthKey = "Stride Length"
//            if let instantaneousStrideLength = environment.instantaneousStrideLength {
//                items.append(RunningAttribute(
//                    title: strideLengthKey,
//                    value: numberFormatter.string(from: NSNumber(floatLiteral: instantaneousStrideLength.value)) ?? "-.-",
//                    unit: instantaneousStrideLength.unit.symbol))
//            } else {
//                items.append(itemPlaceholder(strideLengthKey))
//            }
//        }
//        
//        if environment.rscFeature.contains(.walkingOrRunningStatus) {
//            let walkingRunningStatusKey = "Walking / Running"
//         
//            if let walkingRunning = environment.isRunning {
//                let status: String = walkingRunning ? "Running" : "Walking"
//                let emoji = walkingRunning ? "🏃" : "🚶"
//                items.append(
//                    RunningAttribute(title: walkingRunningStatusKey, value: emoji, unit: status)
//                )
//            } else {
//                items.append(
//                    RunningAttribute(title: walkingRunningStatusKey, value: "-", unit: nil)
//                )
//            }
//        }
        
        return items
    }
}
