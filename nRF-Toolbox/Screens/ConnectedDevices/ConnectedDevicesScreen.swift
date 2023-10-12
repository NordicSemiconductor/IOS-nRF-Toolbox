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
        }
        .environmentObject(viewModel.environment)
            
    }
}

struct ConnectedDevicesView<ScannerContent: View>: View {
    @EnvironmentObject var environment: ConnectedDevicesScreen.ViewModel.Environment
    @State var selectedService: String?
    
    let scannerContent: () -> ScannerContent
    
    init(scannerContent: @escaping () -> ScannerContent) {
        self.scannerContent = scannerContent
    }
    
    var body: some View {
        VStack {
            if environment.connectedDevices.isEmpty {
                emptyState.padding()
            } else {
                ConnectedDeviceList()
                    .environmentObject(environment)
            }
        }
        .sheet(isPresented: $environment.showScanner, content: scannerContent)
        
    }
    
    @ViewBuilder
    var emptyState: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "No Connected Devices",
                // TODO: Is it correct message?
                secondaryText: "Scan for devices and connect to peripheral to begin",
                systemName: "antenna.radiowaves.left.and.right"
            ),
            actions: {
                Button("Start Scan") {
                    environment.showScanner = true
                }
                .buttonStyle(NordicPrimary())
            }
        )
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
    ConnectedDevicesView {
        EmptyView()
            .environmentObject(ConnectedDevicesScreen.ViewModel.Environment())
    }
}
