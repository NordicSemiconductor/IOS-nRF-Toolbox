//
//  ConnectedScreenInitial.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

extension ConnectedDevicesScreen {
    struct InitialStace: View {
        @EnvironmentObject var environment: ViewModel.Environment
        
        var body: some View {
            VStack {
                NoContentView(title: "No Connected Devices", systemImage: "antenna.radiowaves.left.and.right", description: "Scan for devices and connect to peripheral to begin")
                Button("Start Scan") {
                    environment.showScanner = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ConnectedDevicesScreen.InitialStace()
}
