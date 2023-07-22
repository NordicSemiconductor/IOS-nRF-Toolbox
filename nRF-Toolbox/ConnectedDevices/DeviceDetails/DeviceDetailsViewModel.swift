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
import iOS_Bluetooth_Numbers_Database

class DeviceDetailsViewModel: ObservableObject, Identifiable {
    private var cancelables = Set<AnyCancellable>()
    
    let cbPeripheral: CBMPeripheral
    let peripheralManager: Peripheral
    
    var id: String {
        cbPeripheral.identifier.uuidString
    }
    
    var deviceName: String {
        cbPeripheral.name.deviceName
    }
    
    @Published var peripheralRepresentation: AttributeTable
    @Published var serviceHandlers: [ServiceHandler] = []
    
    init(cbPeripheral: CBMPeripheral) {
        self.cbPeripheral = cbPeripheral
        self.peripheralManager = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
        self.peripheralRepresentation = AttributeTable()
        
        self.discoverAllServices()
    }
}

private extension DeviceDetailsViewModel {
    func discoverAllServices() {
        Task {
            for try await service in peripheralManager.discoverServices(serviceUUIDs: nil).autoconnect().values {
                DispatchQueue.main.async {
                    self.peripheralRepresentation.addService(service)
                    
                    switch service.uuid.uuidString {
                    case Service.RunningSpeedAndCadence.runningSpeedAndCadence.uuidString:
                        RunningServiceHandler(peripheral: self.peripheralManager, service: service).map { self.serviceHandlers.append($0) }
                    default:
                        break
                    }
                }
            }
        }
    }
}
