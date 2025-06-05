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
    case heartRate(_ viewModel: DeviceScreen.HeartRateViewModel)
    case healthThermometer(_ viewModel: HealthThermometerViewModel)
    case bloodPressure(_ viewModel: BloodPressureViewModel)
    case running(_ viewModel: RunningServiceViewModel)
    case cycling(_ viewModel: CyclingServiceViewModel)
    case throughput(_ viewModel: ThroughputViewModel)
    case continuousGlucoseMonitoring(_ viewModel: CGMSViewModel)
    case uart(_ viewModel: UARTViewModel)
    case battery(_ viewModel: BatteryViewModel)
    
    var id: String { description }
    
    var description: String {
        switch self {
        case .heartRate:
            return "Heart Monitor"
        case .healthThermometer:
            return "Health Thermometer"
        case .bloodPressure:
            return "Blood Pressure"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .throughput:
            return "Throughput"
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
            case .heartRate(let heartRateServiceViewModel):
                HeartRateView()
                    .environmentObject(heartRateServiceViewModel)
            case .healthThermometer(let healthThermometerViewModel):
                HealthThermometerView()
                    .environmentObject(healthThermometerViewModel)
            case .bloodPressure(let bpsViewModel):
                BloodPressureView()
                    .environmentObject(bpsViewModel)
            case .running(let runningViewModel):
                RunningServiceView()
                    .environmentObject(runningViewModel.environment)
            case .cycling(let cyclingViewModel):
                CyclingDataView()
                    .environmentObject(cyclingViewModel)
            case .throughput(let throughputViewModel):
                ThroughputView()
                    .environmentObject(throughputViewModel)
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
