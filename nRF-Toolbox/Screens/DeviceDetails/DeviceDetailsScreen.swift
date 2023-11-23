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
    let viewModel: DeviceDetailsViewModel
    
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
                NoContentView(
                    title: "No Services",
                    systemImage: "list.bullet.rectangle.portrait",
                    description: "No Supported Services"
                )
            }
        }
        .environmentObject(viewModel.environment)
    }
}

private typealias VM = DeviceDetailsScreen.DeviceDetailsViewModel

struct DeviceDetailsView<ServiceView: View>: View {
    @EnvironmentObject private var environment: VM.Environment
    @EnvironmentObject var rootNavigationVM: RootNavigationViewModel
    @EnvironmentObject var connectedDeviceVM: ConnectedDevicesViewModel
    
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
        if environment.reconnecting {
            NoContentView(title: "Reconnecting . . .", systemImage: "arrow.circlepath")
        } else if let criticalError = environment.criticalError {
            errorView(criticalError)
        } else {
            serviceView
        }
    }
    
    @ViewBuilder
    private func errorView(_ error: VM.CriticalError) -> some View {
        VStack {
            NoContentView(title: error.title, systemImage: "exclamationmark.triangle", description: error.message, style: .error)
            
            Button("Reconnect") {
                Task {
                    await environment.reconnect?()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Button("Remove Device") {
                rootNavigationVM.selectedDevice = nil 
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    Task {
                        try await connectedDeviceVM.disconnectAndRemoveViewModel(environment.deviceID)
                    }
                }
            }
            .buttonStyle(.bordered)
            .foregroundStyle(Color.nordicRed)
        }
    }
    
    @ViewBuilder
    private var serviceView: some View {
        if #available(iOS 17, macOS 14, *) {
            newView
                .inspector(isPresented: $environment.showInspector) {
                    peripheralInspectorScreen
                }
                .toolbar {
                    Button {
                        environment.showInspector.toggle()
                    } label: {
                        Image(systemName: "info")
                            .symbolVariant(.circle)
                    }
                }
        } else {
            oldView
        }
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
            peripheralInspectorScreen
        }
    }

    @ViewBuilder
    private var serviceViews: some View {
        if environment.services.filter(\.isSupported).isEmpty {
            NoContentView(
                title: "No Supported Services",
                systemImage: "list.bullet.rectangle.portrait")
        } else {
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
    }
    
    @ViewBuilder
    private var peripheralInspectorScreen: some View {
        if let vm = environment.peripheralViewModel {
            PeripheralInspectorScreen(viewModel: vm)
                .tabItem {
                    Label("Peripheral", systemImage: "terminal")
                }
        } else {
            NoContentView(title: "No View Model", systemImage: "plus")
        }
    }
}

private typealias Environment = VM.Environment

#Preview {
    NavigationStack {
        DeviceDetailsView(serviceViewContent: { service in
            Text(service.name)
        })
        .environmentObject(
            Environment(
                deviceID: UUID(),
                services: [.runningSpeedAndCadence, .heartRate, .adafruitAccelerometer])
        )
    }
}

#Preview {
    NavigationStack {
        DeviceDetailsView(serviceViewContent: { service in
            Text(service.name)
        })
        .environmentObject(
            Environment(
                deviceID: UUID(),
                services: []))
    }
}

#Preview {
    NavigationStack {
        DeviceDetailsView(serviceViewContent: { service in
            Text(service.name)
        })
        .environmentObject(
            Environment(
                deviceID: UUID(),
                reconnecting: true,
                criticalError: .disconnectedWithError(nil)
            )
        )
    }
}

#Preview {
    NavigationStack {
        DeviceDetailsView(serviceViewContent: { service in
            Text(service.name)
        })
        .environmentObject(
            Environment(
                deviceID: UUID(),
                criticalError: .disconnectedWithError(nil)
            )
        )
    }
}
