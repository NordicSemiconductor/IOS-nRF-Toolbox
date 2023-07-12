//
//  ConnectedDevicesViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine

extension ConnectedDevicesView {
    struct Device: Identifiable {
        let name: String
        let id: UUID
    }
    
    class ViewModel: ObservableObject {
        var devices: [Device] = []
        
        let bluetoothManager: BluetoothManager
        
        init(devices: [Device], bluetoothManager: BluetoothManager = .shared) {
            self.devices = devices
            self.bluetoothManager = bluetoothManager
        }
        
    }
}

extension ConnectedDevicesView.ViewModel {
    private func setupBluetoothManager() {
        Task {
        }
    }
}
