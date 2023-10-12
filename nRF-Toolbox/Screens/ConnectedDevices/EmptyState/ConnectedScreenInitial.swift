//
//  ConnectedScreenInitial.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

extension ConnectedDevicesScreen {
    struct InitialStace: View {
        @EnvironmentObject var environment: ViewModel.Environment
        
        var body: some View {
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
    }
}

#Preview {
    ConnectedDevicesScreen.InitialStace()
}
