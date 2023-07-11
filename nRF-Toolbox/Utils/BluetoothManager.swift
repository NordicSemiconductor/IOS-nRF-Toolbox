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
    
    // Connected Devices
    
    init() {
        centralManager.stateChannel.assign(to: &$state)
    }
    
    func startScan(removeExistingResults: Bool = false) {
        if removeExistingResults {
            scanResults.removeAll()
        }
        
        centralManager.scanForPeripherals(withServices: nil)
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
    
}
