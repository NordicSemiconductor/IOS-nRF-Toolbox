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
        @Published var connectingDevice: ScanResult? = nil
        @Published var showError: Bool = false
        
        let bluetoothManager: BluetoothManager
        private (set) var error: ReadableError? {
            didSet {
                if error != nil {
                    showError = true
                }
            }
        }
        
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
    
    struct ScanResult: Identifiable, Equatable {
        let name: String?
        let rssi: Int
        let id: UUID
        
        let services: [String]
        
        var knownServices: [ServiceRepresentation] {
            services.compactMap { ServiceRepresentation(identifier: $0) }
        }
        
        init(name: String?, rssi: Int, id: UUID, services: [String]) {
            self.name = name
            self.rssi = rssi
            self.id = id
            self.services = services
        }
        
        static func ==(lhs: ScanResult, rhs: ScanResult) -> Bool {
            return lhs.id == rhs.id
        }
    }
}

extension PeripheralScannerView.ViewModel {
    func tryToConnect(device: ScanResult, completion: () -> Void) async {
        if connectingDevice != nil {
            return
        }
        connectingDevice = device
        
        do {
            _ = try await bluetoothManager.tryToConnect(deviceId: device.id)
            connectingDevice = nil
            completion()
        } catch {
            self.error = ReadableError(title: "Error", message: "Failed to connect the peripheral")
        }
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
                sr.map { ScanResult(
                    name: $0.name,
                    rssi: $0.rssi.value,
                    id: $0.peripheral.identifier,
                    services: $0.advertisementData.serviceUUIDs?.compactMap { $0.uuidString } ?? []
                ) }
            }
            .assign(to: &$devices)
    }
}
