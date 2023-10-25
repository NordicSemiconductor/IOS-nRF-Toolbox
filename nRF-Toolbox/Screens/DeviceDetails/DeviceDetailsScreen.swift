//
//  DeviceDetailsScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

struct DeviceDetailsScreen: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DeviceDetailsView { service in
            switch service {
            case .runningSpeedAndCadence:
                if let vm = viewModel.runningServiceViewModel {
                    RunningServiceScreen(viewModel: vm)
                }
            case .heartRate:
                if let vm = viewModel.heartRateServiceViewModel {
                    HeartRateScreen(viewModel: vm)
                }
            default:
                EmptyView()
            }
        } signalChartContent: {
            SignalChartScreen(viewModel: viewModel.signalChartViewModel)
        }
        .environmentObject(viewModel.environment)
        .task {
            await viewModel.discoverSupportedServices()
        }
    }
}

struct DeviceDetailsView<ServiceView: View, SignalView: View>: View {
    @EnvironmentObject var environment: DeviceDetailsScreen.ViewModel.Environment
    
    let serviceViewContent: (Service) -> ServiceView
    let signalChartContent: () -> SignalView
    
    init(
        @ViewBuilder serviceViewContent: @escaping (Service) -> ServiceView,
        @ViewBuilder signalChartContent: @escaping () -> SignalView
    ) {
        self.serviceViewContent = serviceViewContent
        self.signalChartContent = signalChartContent
    }
    
    var body: some View {
        TabView {
            ForEach(environment.services.filter(\.isSupported)) { service in
                serviceViewContent(service)
                    .tabItem {
                        Label(
                            title: { Text(service.name) },
                            icon: { service.systemImage }
                        )
                    }
            }
            
            if let vm = environment.attributeTableViewModel?() {
                AttributeTableScreen(viewModel: vm)
                    .tabItem {
                        Label("Attribute table", systemImage: "table")
                    }
            }
            
            signalChartContent()
                .tabItem {
                    Label("Signal Chart", systemImage: "chart.bar")
                }
            
        }
        .navigationTitle(environment.peripheralName ?? "Device Details")
    }
}

private typealias Environment = DeviceDetailsScreen.ViewModel.Environment

#Preview {
    NavigationStack {
        DeviceDetailsView(serviceViewContent: { service in
            Text(service.name)
        }, signalChartContent: {
            Text("Chart View")
        })
        .navigationTitle("Device Name")
        .environmentObject(Environment(services: [.runningSpeedAndCadence, .heartRate, .adafruitAccelerometer]))
    }
}
