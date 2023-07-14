//
//  ConnectedDevicesView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct ConnectedDevicesView: View {
    @StateObject var viewModel = ViewModel()
    @State var selectedService: String?
    
    @State var showScanner = false
    
    var body: some View {
        VStack {
            if viewModel.devices.isEmpty {
                emptyState.padding()
            } else {
                deviceList
            }
        }
    }
    
    @ViewBuilder
    var emptyState: some View {
        ContentUnavailableView(
            configuration: ContentUnavailableConfiguration(
                text: "No Connected Devices",
                // TODO: Is it correct message?
                secondaryText: "Scan for devices and connect to peripheral to begin",
                systemName: "antenna.radiowaves.left.and.right",
                buttonConfiguration: ContentUnavailableConfiguration.ButtonConfiguration(
                    title: "Start Scan", action: {
                        showScanner = true 
                    })
            )
        )
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                PeripheralScannerView()
            }
        }
    }
    
    var deviceList: some View {
        List {
            ForEach($viewModel.handlers) { $device in
                VStack {
                    Text(device.peripheralRepresentation.name)
                    Text("\(device.peripheralRepresentation.services.count)")
                    HStack {
                        ForEach(device.peripheralRepresentation.services) {
                            Text($0.name ?? "some service")
                        }
                    }
                }
            }
        }
    }
}

struct ConnectedDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConnectedDevicesView()
                .navigationTitle("Connected Devices")
        }
    }
}
