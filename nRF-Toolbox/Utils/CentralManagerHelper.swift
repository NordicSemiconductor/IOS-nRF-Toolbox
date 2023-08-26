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
    enum Err: Swift.Error {
        case peripheralNotFound, timeout
    }
    
    private var cancelables = Set<AnyCancellable>()
    
    let centralManager = CentralManager()
    
    static var shared = CentralManagerHelper()
    
    @Published var scanResults: [ScanResult] = []
    @MainActor @Published var peripheralManagers: [DeviceDetailsViewModel] = []
    
    func startScan(removeExistingResults: Bool = false) {
        if removeExistingResults {
            scanResults.removeAll()
        }
        
        centralManager.scanForPeripherals(withServices: nil)
            .autoconnect()
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
    
    func tryToConnect(deviceId: UUID) async throws {
        guard let sr = scanResults.first(where: { $0.peripheral.identifier == deviceId }) else {
            throw Err.peripheralNotFound
        }
        
        let connectionPublisher = centralManager.connect(sr.peripheral)
            .autoconnect()
            .share()
        
        let connectedPeripheral = try await connectionPublisher
            .timeout(.seconds(3), scheduler: DispatchQueue.main, customError: { Err.timeout })
            .value
        
        let handler = DeviceDetailsViewModel(cbPeripheral: connectedPeripheral) { [weak self] p  in
            try await self?.tryReconnect(peripheral: connectedPeripheral)
        }
        
        connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                DispatchQueue.main.async {
                    switch completion {
                    case .finished:
                        self.peripheralManagers.removeAll(where: { $0.cbPeripheral.identifier == deviceId })
                    case .failure(let e):
                        handler.disconnectedError = e
                    }
                }
            } receiveValue: { _ in
                
            }
            .store(in: &cancelables)
        
        DispatchQueue.main.async {
            self.peripheralManagers.append(handler)
        }
    }
    
    private func tryReconnect(peripheral: CBPeripheral) async throws {
        
    }
}
