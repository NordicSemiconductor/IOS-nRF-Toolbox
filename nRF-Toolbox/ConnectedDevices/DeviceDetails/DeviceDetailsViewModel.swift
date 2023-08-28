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
    
    let cbPeripheral: CBPeripheral
    let peripheralManager: Peripheral
    
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
        self.peripheralManager = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
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
    
    func discover() {
        peripheralManager.discoverServices(serviceUUIDs: nil)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .flatMap { service in
                self.attributeTable.addService(service)
                return self.peripheralManager.discoverCharacteristics(nil, for: service).autoconnect()
            }
            .flatMap { characteristic in
                self.attributeTable.addCharacteristic(characteristic)
                return self.peripheralManager.discoverDescriptors(for: characteristic).autoconnect()
            }
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { descriptor in
                self.attributeTable.addDescriptor(descriptor)
            })
            .store(in: &cancelables)
    }
}

private extension DeviceDetailsViewModel {
    
    func discoverAllServices() {
        Task {
            for try await service in peripheralManager.discoverServices(serviceUUIDs: nil).autoconnect().timeout(.seconds(5), scheduler: DispatchQueue.main).values {
                DispatchQueue.main.async {
//                    self.peripheralRepresentation.addService(service)
                    
                    switch service.uuid.uuidString {
                    case Service.runningSpeedAndCadence.uuidString:
                        _ = RunningServiceHandler(peripheral: self.peripheralManager, service: service).map { self.serviceHandlers.replacedOrAppended($0, compareBy: \.id) }
//                        RunningServiceHandler(peripheral: self.peripheralManager, service: service).map { self.serviceHandlers.append($0) }
                    default:
                        break
                    }
                }
            }
        }
    }
}
