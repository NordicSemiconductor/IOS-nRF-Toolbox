//
//  PeripheralScannerViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension PeripheralScannerView {
    class ViewModel: ObservableObject {
        let bluetoothManager: BluetoothManager
        
        var state: State = .scanning
        var devices: [ScanResult] = []
        
        init(bluetoothManager: BluetoothManager, state: State = .scanning, devices: [ScanResult] = []) {
            self.state = state
            self.devices = devices
            self.bluetoothManager = bluetoothManager
        }
    }
}

extension PeripheralScannerView.ViewModel {
    enum State {
        case scanning, unsupported, disabled
    }
    
    struct ScanResult: Identifiable {
        let name: String
        let id: UUID
    }
}
