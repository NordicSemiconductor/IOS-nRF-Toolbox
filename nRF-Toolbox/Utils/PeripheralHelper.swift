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
import CoreBluetoothMock

class PeripheralHelper: ObservableObject, Identifiable {
    private var cancelables = Set<AnyCancellable>()
    
    let cbPeripheral: CBMPeripheral
    let peripheralManager: Peripheral
    
    var id: String {
        cbPeripheral.identifier.uuidString
    }
    
    @Published var peripheralRepresentation: PeripheralStructure
    
    init(cbPeripheral: CBMPeripheral) {
        self.cbPeripheral = cbPeripheral
        self.peripheralManager = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
        self.peripheralRepresentation = PeripheralStructure(cbPeripheral: cbPeripheral)
        
        $peripheralRepresentation.sink { p in
            print("\(p.name ?? "na"), services: \(p.services.count)")
            self.objectWillChange.send()
        }
        .store(in: &cancelables)
        
        self.discover()
    }
    
    func serviceCount() -> Int {
        return peripheralRepresentation.services.count
    }
}

private extension PeripheralHelper {
    
    func discover() {
        Task {
            for try await service in peripheralManager.discoverServices(serviceUUIDs: nil).autoconnect().receive(on: DispatchQueue.main).values {
                self.peripheralRepresentation.addService(service)
                    
                print(#function)
                objectWillChange.send()
                
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
