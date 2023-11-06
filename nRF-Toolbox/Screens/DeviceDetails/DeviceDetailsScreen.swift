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
                Text("No Supported Services")
            }
        }
        .environmentObject(viewModel.environment)
    }
}

struct DeviceDetailsView<ServiceView: View>: View {
    @EnvironmentObject var environment: DeviceDetailsScreen.ViewModel.Environment
    
    @State private var showInspector: Bool = false
    
    let serviceViewContent: (Service) -> ServiceView
    
    #if os(iOS)
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    #endif
    
    init(@ViewBuilder serviceViewContent: @escaping (Service) -> ServiceView) {
        self.serviceViewContent = serviceViewContent
    }
    
    var body: some View {
        mainView
            .navigationTitle(environment.peripheralName ?? "Device Details")
    }
    
    @ViewBuilder
    private var mainView: some View {
        if #available(iOS 17, macOS 14, *) {
            newView
                .toolbar {
                    ToolbarItem {
                        Button {
                            showInspector.toggle()
                        } label: {
                            Image(systemName: "square.trailingthird.inset.filled")
                        }
                    }
                }
                .inspector(isPresented: $showInspector) {
                    inspectorContent
                }
                
        } else {
            oldView
        }
    }
    
    @ViewBuilder
    private var inspectorContent: some View {
        #if os(macOS)
        peripheralScreen
        #else
        if idiom == .phone {
            NavigationView {
                peripheralScreen
                    .navigationTitle("Peripheral")
            }
        } else {
            peripheralScreen
        }
        #endif
    }

    @ViewBuilder
    private var newView: some View {
        if environment.services.filter(\.isSupported).count > 1 {
            TabView {
                serviceViews
            }
        } else {
            serviceViews
        }
    }
    
    @ViewBuilder
    private var oldView: some View {
        TabView {
            serviceViews
            peripheralScreen
        }
    }

    @ViewBuilder
    private var serviceViews: some View {
        ForEach(environment.services.filter(\.isSupported)) { service in
            serviceViewContent(service)
                .tabItem {
                    Label(
                        title: { Text(service.name) },
                        icon: { service.systemImage }
                    )
                }
        }
    }
    
    @ViewBuilder
    private var peripheralScreen: some View {
        PeripheralScreen(viewModel: environment.peripheralViewModel)
            .tabItem {
                Label("Peripheral", systemImage: "terminal")
            }
    }
}

private typealias Environment = DeviceDetailsScreen.ViewModel.Environment

#Preview {
    NavigationStack {
        DeviceDetailsView(serviceViewContent: { service in
            Text(service.name)
        })
        .navigationTitle("Device Name")
        .environmentObject(Environment(services: [.runningSpeedAndCadence, .heartRate, .adafruitAccelerometer]))
    }
}
