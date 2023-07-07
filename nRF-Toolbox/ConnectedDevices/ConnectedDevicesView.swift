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
                systemName: "flipphone",
                buttonConfiguration: ContentUnavailableConfiguration.ButtonConfiguration(
                    title: "Start Scan", action: {
                        
                    })
            )
        )
    }
    
    var deviceList: some View {
        Text("Devices")
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
