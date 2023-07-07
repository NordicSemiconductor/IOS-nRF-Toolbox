//
//  BluetoothManager.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import iOS_Common_Libraries

class BluetoothManager: ObservableObject {
    let centralManager = CentralManager()
    
    @Published var state: CBManagerState = .unknown
    @Published var scanResults: [ScanResult] = []
    
    init() {
        centralManager.stateChannel.assign(to: &$state)
        
        
    }
    
    func startScan() {
        centralManager.scanForPeripherals(withServices: nil)
            .sink { completion in
                
            } receiveValue: { scanResult in
                _ = self.scanResults.replacedOrAppended(scanResult, compareBy: \.peripheral.identifier)
            }

    }
    
}
