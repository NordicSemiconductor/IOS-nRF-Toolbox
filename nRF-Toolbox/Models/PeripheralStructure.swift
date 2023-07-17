//
//  PeripheralStructure.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

struct PeripheralStructure: Identifiable, Equatable {
    private typealias S = iOS_Bluetooth_Numbers_Database.Service
    private typealias C = iOS_Bluetooth_Numbers_Database.Characteristic
    private typealias D = iOS_Bluetooth_Numbers_Database.Descriptor
    
    struct Service: Identifiable, Equatable {
        struct Characteristic: Identifiable, Equatable {
            struct Descriptor: Identifiable, Equatable {
                let cbDescriptor: CBDescriptor
                let id: String
                let name: String?
            }
            
            let cbCharacteristic: CBCharacteristic
            let id: String
            let name: String?
            fileprivate (set) var descriptors: [Descriptor] = []
        }
        
        let cbService: CBService
        let id: String
        let name: String?
        fileprivate (set) var characteristics: [Characteristic] = []
    }
    
    let cbPeripheral: CBPeripheral
    var id: String {
        cbPeripheral.identifier.uuidString
    }
    
    var name: String {
        cbPeripheral.name ?? "n/a"
    }
    
    private (set) var services: [Service] = []
    
    init(cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }
    
    static func == (lhs: PeripheralStructure, rhs: PeripheralStructure) -> Bool {
        lhs.id == rhs.id && lhs.services == rhs.services
    }
    
    mutating func addService(_ cbService: CBService) {
        let service = Service(
            cbService: cbService,
            id: cbService.uuid.uuidString,
            name: S.find(by: cbService.uuid)?.name
        )
        services.append(service)
        
        print("added service: \(service.name ?? "no name")")
    }
    
    mutating func addCharacteristic(_ cbCharacteristic: CBCharacteristic) {
        guard let serviceIndex = services.enumerated().first(where: { $0.element.id == cbCharacteristic.service?.uuid.uuidString })?.offset else {
            return
        }
        
        let charateristic = Service.Characteristic(
            cbCharacteristic: cbCharacteristic,
            id: cbCharacteristic.uuid.uuidString,
            name: C.find(by: cbCharacteristic.uuid)?.name
        )
        services[serviceIndex].characteristics.append(charateristic)
    }
    
    mutating func addDescriptor(_ cbDescriptor: CBDescriptor) {
        guard let serviceId = cbDescriptor.characteristic?.service?.uuid.uuidString,
              let charateristicId = cbDescriptor.characteristic?.uuid.uuidString else {
            return
        }
        
        guard let serviceIndex = services.enumerated().first(where: { $0.element.id == serviceId })?.offset else {
            return
        }
        
        guard let characteristicIndex = services[serviceIndex].characteristics.enumerated().first(where: { $0.element.id == charateristicId })?.offset else {
            return
        }
        
        let descriptor = Service.Characteristic.Descriptor(
            cbDescriptor: cbDescriptor,
            id: cbDescriptor.uuid.uuidString,
            name: D.find(by: cbDescriptor.uuid)?.name
        )
        services[serviceIndex].characteristics[characteristicIndex].descriptors.append(descriptor)
    }
}
