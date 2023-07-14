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
import Combine

class BluetoothManager: ObservableObject {
    enum Error: Swift.Error {
        case peripheralNotFound, timeout
    }
    
    private var cancelables = Set<AnyCancellable>()
    
    let centralManager = CentralManager()
    
    static var shared = BluetoothManager()
    
    @Published var state: CBManagerState = .unknown
    @Published var scanResults: [ScanResult] = []
    
    var sr: [ScanResult] = []
    
    @Published var peripheralManagers: [PeripheralHandler] = []
    
    // Connected Devices
    
    init() {
        centralManager.stateChannel.assign(to: &$state)
        
        handleConnectedDevices()
    }
    
    func startScan(removeExistingResults: Bool = false) {
        if removeExistingResults {
            scanResults.removeAll()
        }
        
        centralManager.scanForPeripherals(withServices: nil)
            .filter { sr in
                sr.name != nil 
            }
            .scan([ScanResult](), { acc, sr in
                return acc.replaceOrAppend(sr, compareBy: \.peripheral.identifier)
            })
            .sink { completion in
                
            } receiveValue: { scanResult in
                self.scanResults = scanResult
            }
            .store(in: &cancelables)
    }
    
    func tryToConnect(deviceId: UUID) async throws -> CBPeripheral {
        guard let sr = scanResults.first(where: { $0.peripheral.identifier == deviceId }) else {
            throw Error.peripheralNotFound
        }
        
        return try await centralManager.connect(sr.peripheral)
            .autoconnect()
            .timeout(.seconds(3), scheduler: DispatchQueue.main, customError: { Error.timeout })
            .value
    }
    
    private func handleConnectedDevices() {
        Task {
            for await peripheral in centralManager.connectedPeripheralChannel.values {
                if peripheral.1 != nil {
                    continue
                }
                
                DispatchQueue.main.async {
                    self.peripheralManagers.replacedOrAppended(PeripheralHandler(cbPeripheral: peripheral.0), compareBy: \.cbPeripheral.identifier)
                }
            }
        }
    }
}
