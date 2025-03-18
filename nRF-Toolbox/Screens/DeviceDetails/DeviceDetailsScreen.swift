//
//  DeviceDetailsScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

// MARK: - DeviceDetailsScreen

struct DeviceDetailsScreen: View {
    let viewModel: DeviceDetailsViewModel
    
    var body: some View {
        DeviceDetailsView { _ in
            NoContentView(
                title: "No Services",
                systemImage: "list.bullet.rectangle.portrait",
                description: "No Supported Services"
            )
        }
        .environmentObject(viewModel.environment)
    }
}

private typealias VM = DeviceDetailsViewModel

// MARK: - DeviceDetailsView

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
            NoContentView(title: "No View Model", systemImage: "plus")
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
                // TODO: Unselect Device instead
//                rootNavigationVM.selectedDevice = nil
                
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
}

private typealias Environment = VM.Environment

