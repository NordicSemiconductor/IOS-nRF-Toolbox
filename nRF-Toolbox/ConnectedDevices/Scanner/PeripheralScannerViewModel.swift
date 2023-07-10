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
        @Published var state: State = .scanning
        @Published var devices: [ScanResult] = []
        
        let bluetoothManager: BluetoothManager
        
        init(bluetoothManager: BluetoothManager = BluetoothManager.shared, state: State = .scanning, devices: [ScanResult] = []) {
            self.state = state
            self.devices = devices
            
            self.bluetoothManager = bluetoothManager
            
            setupManager(btManager: bluetoothManager)
            bluetoothManager.startScan()
        }
    }
}

extension PeripheralScannerView.ViewModel {
    enum State {
        case scanning, unsupported, disabled, unauthorized
    }
    
    struct ScanResult: Identifiable {
        let name: String?
        let rssi: Int
        let id: UUID
    }
}

extension PeripheralScannerView.ViewModel {
    private func setupManager(btManager: BluetoothManager) {
        btManager.centralManager.stateChannel
            .map { state -> State in
                switch state {
                case .poweredOff: return .disabled
                case .unauthorized: return .unauthorized
                case .unsupported: return .unsupported
                default: return .scanning
                }
            }
            .assign(to: &$state)
        
        btManager.$scanResults
            .map { sr -> [ScanResult] in
                sr.map { ScanResult(name: $0.name, rssi: $0.rssi.value, id: $0.peripheral.identifier) }
            }
            .assign(to: &$devices)
    }
}
