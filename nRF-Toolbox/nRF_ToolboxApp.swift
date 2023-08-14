//
//  nRF_ToolboxApp.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library
import JGProgressHUD_SwiftUI

@main
struct nRF_ToolboxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    BluetoothEmulation.shared.simulateState()
                    BluetoothEmulation.shared.simulatePeripherals()
                }
        }
    }
}
