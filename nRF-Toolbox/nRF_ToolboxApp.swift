//
//  nRF_ToolboxApp.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock

@main
struct nRF_ToolboxApp: App {
    @StateObject var hudState = HUDState()
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .onAppear {
                    BluetoothEmulation.shared.simulateState()
                    BluetoothEmulation.shared.simulatePeripherals()
                }
                .environmentObject(hudState)
                .hud(isPresented: $hudState.isPresented) {
                    Label(hudState.title, systemImage: hudState.systemImage)
                }
        }
    }
}
