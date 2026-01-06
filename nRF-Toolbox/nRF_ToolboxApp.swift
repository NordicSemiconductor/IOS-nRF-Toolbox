//
//  nRF_ToolboxApp.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import SwiftUI
import iOS_BLE_Library_Mock

// MARK: - App

@main
struct nRF_ToolboxApp: App {
    
    // MARK: view
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .onAppear {
                    BluetoothEmulation.shared.simulateState()
                    BluetoothEmulation.shared.simulatePeripherals()
                }
                .setupTranslucentBackground()
                .environment(\.modelContext, SwiftDataContextManager.shared.context!)
        }
    }
}
