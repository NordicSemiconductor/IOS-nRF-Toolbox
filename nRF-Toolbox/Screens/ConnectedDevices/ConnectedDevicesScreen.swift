//
//  ConnectedDevicesView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct ConnectedDevicesScreen: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        ConnectedDevicesView {
            NavigationStack {
                PeripheralScannerScreen(viewModel: viewModel.scannerViewModel)
#if os(macOS)
                    .frame(minWidth: 400, minHeight: 450)
#endif
            }
        } detailedScreen: { device in
            DeviceDetailsScreen(viewModel: viewModel.environment.deviceViewModel(device))
        }
        .environmentObject(viewModel.environment)
    }
}

struct ConnectedDevicesView<ScannerScreen: View, DetailedScreen: View>: View {
    @EnvironmentObject var environment: ConnectedDevicesScreen.ViewModel.Environment
    @State var selectedService: String?
    
    let scannerScreen: () -> ScannerScreen
    
    typealias DetailedScreenBuilder = (ConnectedDevicesScreen.ViewModel.Device) -> DetailedScreen
    let detailedScreen: (ConnectedDevicesScreen.ViewModel.Device) -> DetailedScreen
    
    init(
        @ViewBuilder scannerScreen: @escaping () -> ScannerScreen,
        @ViewBuilder detailedScreen: @escaping DetailedScreenBuilder
    ) {
        self.scannerScreen = scannerScreen
        self.detailedScreen = detailedScreen
    }
    
    var body: some View {
        VStack {
            if environment.connectedDevices.isEmpty {
                ConnectedDevicesScreen.InitialStace()
                    .padding()
                    .environmentObject(environment)
            } else {
                ConnectedDeviceList(detailedScreen: detailedScreen)
                    .environmentObject(environment)
            }
        }
        .sheet(isPresented: $environment.showScanner, content: scannerScreen)
        
    }
    /*
    var deviceList: some View {
        List {
            ForEach(viewModel.peripheralManagers) { peripheral in
                NavigationLink {
                    DeviceDetailsView(peripheralHandler: peripheral)
                } label: {
                    DeviceItem(peripheral: peripheral)
                }
            }
            Button("Connect another device") {
//               showScanner = true
            }
        }
    }
     */
}

#Preview {
    NavigationStack {
        ConnectedDevicesView(scannerScreen: {
            EmptyView()
        }, detailedScreen: { _ in
            EmptyView()
        })
        .environmentObject(ConnectedDevicesScreen.ViewModel.Environment(connectedDevices: [
            ConnectedDevicesScreen.ViewModel.Device(name: "Device", id: UUID())
        ]))
    }
}

#Preview {
    NavigationStack {
        ConnectedDevicesView(scannerScreen: {
            EmptyView()
        }, detailedScreen: { _ in
            EmptyView()
        })
        .environmentObject(ConnectedDevicesScreen.ViewModel.Environment(connectedDevices: []))
    }
}
