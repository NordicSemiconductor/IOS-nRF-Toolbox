//
//  PeripheralHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import Combine
import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database


class DeviceDetailsViewModel: ObservableObject, Identifiable {
    private var cancelables = Set<AnyCancellable>()
    
    let cbPeripheral: CBPeripheral
    let peripheral: Peripheral
    
    private let supportedServices: [CBUUID] = [.runningSpeedCadence]
    
    var id: String {
        cbPeripheral.identifier.uuidString
    }
    
    var deviceName: String {
        cbPeripheral.name.deviceName
    }
    
    @Published var serviceHandlers: [ServiceHandler] = []
    @Published var attributeTable = AttributeTable()
    
    @Published var disconnectedError: Error? = nil
    
    private let requestReconnect: (CBPeripheral) async throws -> ()
    private let cancelConnection: (CBPeripheral) async throws -> ()
    
    init(cbPeripheral: CBMPeripheral,
         requestReconnect: @escaping (CBPeripheral) async throws -> (),
         cancelConnection: @escaping (CBPeripheral) async throws -> ()
    ) {
        self.cbPeripheral = cbPeripheral
        self.peripheral = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
        self.requestReconnect = requestReconnect
        self.cancelConnection = cancelConnection
        
        self.discoverAllServices()
    }
    
    func tryToReconnect() async {
        do {
            try await requestReconnect(cbPeripheral)
            
            DispatchQueue.main.async {
                self.disconnectedError = nil
                self.serviceHandlers.removeAll()
                self.discoverAllServices()
            }
        } catch let e {
            self.disconnectedError = e
        }
    }
    
    func cancelPeripheralConnection() async {
        do {
            try await cancelConnection(cbPeripheral)
        } catch let e {
            self.disconnectedError = e
        }
    }
    
    func discover() async throws {
        let services = try await peripheral.discoverServices(serviceUUIDs: nil).value
        for s in services {
            let characteristics = try await peripheral.discoverCharacteristics(nil, for: s).value
            for c in characteristics {
                let descriptors = try await peripheral.discoverDescriptors(for: c).value
            }
            DispatchQueue.main.async {
                self.attributeTable.addService(s)
            }
        }
    }
}

private extension DeviceDetailsViewModel {
    
    func discoverAllServices() {
        Task {
            let services = try await peripheral.discoverServices(serviceUUIDs: supportedServices).timeout(.seconds(5), scheduler: DispatchQueue.main).value
            
            for service in services {
                DispatchQueue.main.async {
                    switch service.uuid {
                    case .runningSpeedCadence:
                        _ = RunningServiceHandler(peripheral: self.peripheral, service: service).map { self.serviceHandlers.replacedOrAppended($0, compareBy: \.id) }
                    default:
                        break
                    }
                }
            }
        }
    }
}
