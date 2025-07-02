//
//  SupportedServiceViewModel.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 4/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - SupportedServiceViewModel

protocol SupportedServiceViewModel {
    
    var attachedView: SupportedServiceAttachedView { get }
    
    func onConnect() async
    func onDisconnect()
}

// MARK: - SupportedServiceAttachedView

enum SupportedServiceAttachedView: View, CustomStringConvertible, Identifiable {
    case blinky(_ viewModel: BlinkyViewModel)
    case heartRate(_ viewModel: HeartRateViewModel)
    case healthThermometer(_ viewModel: HealthThermometerViewModel)
    case bloodPressure(_ viewModel: BloodPressureViewModel)
    case cuffPressure(_ viewModel: CuffPressureViewModel)
    case running(_ viewModel: RunningServiceViewModel)
    case cycling(_ viewModel: CyclingServiceViewModel)
    case throughput(_ viewModel: ThroughputViewModel)
    case glucose(_ viewModel: GlucoseViewModel)
    case continuousGlucoseMonitoring(_ viewModel: CGMSViewModel)
    case uart(_ viewModel: UARTViewModel)
    case battery(_ viewModel: BatteryViewModel)
    
    var id: String { description }
    
    var description: String {
        switch self {
        case .blinky:
            return "LED Button Service"
        case .heartRate:
            return "Heart Monitor"
        case .healthThermometer:
            return "Health Thermometer"
        case .bloodPressure:
            return "Blood Pressure"
        case .cuffPressure:
            return "Cuff Pressure"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .throughput:
            return "Throughput"
        case .glucose:
            return "Glucose Service"
        case .continuousGlucoseMonitoring:
            return "Continuous Glucose Monitoring Service"
        case .uart:
            return "UART"
        case .battery:
            return "Battery"
        }
    }
    
    var body: some View {
        Section(description) {
            switch self {
            case .blinky(let blinkyViewModel):
                BlinkyView()
                    .environmentObject(blinkyViewModel)
            case .heartRate(let heartRateServiceViewModel):
                HeartRateView()
                    .environmentObject(heartRateServiceViewModel)
            case .healthThermometer(let healthThermometerViewModel):
                HealthThermometerView()
                    .environmentObject(healthThermometerViewModel)
            case .bloodPressure(let bpsViewModel):
                BloodPressureView()
                    .environmentObject(bpsViewModel)
            case .cuffPressure(let cuffViewModel):
                CuffPressureView()
                    .environmentObject(cuffViewModel)
            case .running(let runningViewModel):
                RunningServiceView()
                    .environmentObject(runningViewModel.environment)
            case .cycling(let cyclingViewModel):
                CyclingDataView()
                    .environmentObject(cyclingViewModel)
            case .throughput(let throughputViewModel):
                ThroughputView()
                    .environmentObject(throughputViewModel)
            case .glucose(let glucoseViewModel):
                GlucoseView()
                    .environmentObject(glucoseViewModel)
            case .continuousGlucoseMonitoring(let cgmsViewModel):
                CGMSView()
                    .environmentObject(cgmsViewModel)
            case .uart(let uartViewModel):
                UARTView()
                    .environmentObject(uartViewModel)
            case .battery(let batteryViewModel):
                BatteryView()
                    .environmentObject(batteryViewModel)
            }
        }
    }
}
