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
            if service.isSupported {
                Image(systemName: "42")
            } else {
                Image(systemName: "42")
            }
        }
        .environmentObject(viewModel.environment)
        .task {
            await viewModel.discoverSupportedServices()
        }
    }
}

struct DeviceDetailsView<ServiceView: View>: View {
    @EnvironmentObject var environment: DeviceDetailsScreen.ViewModel.Environment
    
    let serviceViewContent: (Service) -> ServiceView
    
    init(@ViewBuilder serviceViewContent: @escaping (Service) -> ServiceView) {
        self.serviceViewContent = serviceViewContent
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
            
            Text("Attribue Table")
                .tabItem {
                    Label("Attribute table", systemImage: "table")
                }
            
            Text("Signal Chart")
                .tabItem {
                    Label("Signal Chart", systemImage: "chart.bar")
                }
        }
    }
}

private typealias Environment = DeviceDetailsScreen.ViewModel.Environment

#Preview {
    NavigationStack {
        DeviceDetailsView { s in
            Text(s.name)
        }
        .navigationTitle("Device Name")
        .environmentObject(Environment(services: [.runningSpeedAndCadence, .heartRate, .adafruitAccelerometer]))
    }
}
