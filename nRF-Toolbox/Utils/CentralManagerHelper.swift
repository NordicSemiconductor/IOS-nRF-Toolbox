//
//  CentralManagerHelper.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import iOS_Common_Libraries
import Combine

class CentralManagerHelper: ObservableObject {
    enum Error: Swift.Error {
        case peripheralNotFound, timeout
    }
    
    private var cancelables = Set<AnyCancellable>()
    
    let centralManager = CentralManager()
    
    static var shared = CentralManagerHelper()
    
    @Published var scanResults: [ScanResult] = []
    @Published var peripheralManagers: [DeviceDetailsViewModel] = []
    
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
        
        let peripheral = try await centralManager.connect(sr.peripheral)
            .autoconnect()
            .timeout(.seconds(3), scheduler: DispatchQueue.main, customError: { Error.timeout })
            .value
        
        DispatchQueue.main.async {
            self.peripheralManagers.append(DeviceDetailsViewModel(cbPeripheral: peripheral))            
        }
        
        return peripheral
    }
}
