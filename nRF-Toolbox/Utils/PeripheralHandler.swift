//
//  PeripheralHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import Combine

class PeripheralHandler: ObservableObject, Identifiable {
    private var cancelables = Set<AnyCancellable>()
    
    let cbPeripheral: CBPeripheral
    let peripheralManager: PeripheralManager
    
    var id: String {
        cbPeripheral.identifier.uuidString
    }
    
    @Published var peripheralRepresentation: PeripheralStructure
    
    init(cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
        self.peripheralManager = PeripheralManager(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
        self.peripheralRepresentation = PeripheralStructure(cbPeripheral: cbPeripheral)
        
        self.discover()
    }
    
}

private extension PeripheralHandler {
    func discover() {
        Task {
        for try await service in peripheralManager.discoverServices(serviceUUIDs: nil).autoconnect().receive(on: DispatchQueue.main).values {
                self.peripheralRepresentation.addService(service)
                
                Task {
                    for try await characteristic in peripheralManager.discoverCharacteristics(nil, for: service).autoconnect().receive(on: DispatchQueue.main).values {
                        self.peripheralRepresentation.addCharacteristic(characteristic)
                        
                        Task {
                            for try await descriptor in peripheralManager.discoverDescriptors(for: characteristic).autoconnect().receive(on: DispatchQueue.main).values {
                                self.peripheralRepresentation.addDescriptor(descriptor)
                            }
                        }
                    }
                }
            }
        }
    }
}
