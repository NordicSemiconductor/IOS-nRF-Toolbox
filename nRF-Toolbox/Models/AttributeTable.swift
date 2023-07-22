//
//  AttributeTable.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

protocol StringIdentifiable  {
    var id: String { get }
}

struct AttributeTable {
    typealias S = iOS_Bluetooth_Numbers_Database.Service
    typealias C = iOS_Bluetooth_Numbers_Database.Characteristic
    typealias D = iOS_Bluetooth_Numbers_Database.Descriptor
    
    struct Service: Identifiable, StringIdentifiable, Equatable, NamedItem {
        struct Characteristic: Identifiable, StringIdentifiable, Equatable, NamedItem {
            struct Descriptor: Identifiable, StringIdentifiable, Equatable, NamedItem {
                let cbDescriptor: CBDescriptor
                let id: String
                let name: String?
            }
            
            let cbCharacteristic: CBCharacteristic
            let id: String
            let name: String?
            fileprivate (set) var descriptors: [Descriptor] = []
            
            var prepertiesDescription: String {
                switch cbCharacteristic.properties {
                case [.read, .write, .notify]: return "RWN"
                case [.read, .write]: return "RW"
                case [.read, .notify]: return "RN"
                case [.read]: return "R"
                case [.write]: return "W"
                case [.notify]: return "N"
                default: return ""
                }
            }
        }
        
        let cbService: CBService
        let id: String
        let name: String?
        fileprivate (set) var characteristics: [Characteristic] = []
    }
    
    private (set) var services: [Service] = []
    
    mutating func addService(_ cbService: CBService) {
        var service = Service(
            cbService: cbService,
            id: cbService.uuid.uuidString,
            name: S.find(by: cbService.uuid)?.name
        )
        
        service.characteristics = cbService.characteristics?.map { cbch in
            var ch = Service.Characteristic(
                cbCharacteristic: cbch,
                id: cbch.uuid.uuidString,
                name: C.find(by: cbch.uuid.uuidString)?.name
            )
            
            ch.descriptors = cbch.descriptors?.map { cbd in
                Service.Characteristic.Descriptor(
                    cbDescriptor: cbd,
                    id: cbd.uuid.uuidString,
                    name: D.find(by: cbd.uuid.uuidString)?.name
                )
            } ?? []
            
            return ch
        } ?? []
        
        services.replacedOrAppended(service)
    }
    
    mutating func addCharacteristic(_ cbCharacteristic: CBCharacteristic) {
        guard let service = cbCharacteristic.service else {
            return
        }
        guard let serviceIndex = services.enumerated()
            .first(where: { $0.element.id == service.uuid.uuidString })?
            .offset else {
            return
        }
        
        var charateristic = Service.Characteristic(
            cbCharacteristic: cbCharacteristic,
            id: cbCharacteristic.uuid.uuidString,
            name: C.find(by: cbCharacteristic.uuid)?.name
        )
        
        charateristic.descriptors = cbCharacteristic.descriptors?.map { cbd in
            Service.Characteristic.Descriptor(
                cbDescriptor: cbd,
                id: cbd.uuid.uuidString,
                name: D.find(by: cbd.uuid.uuidString)?.name
            )
        } ?? []
        
        services[serviceIndex].characteristics.append(charateristic)
    }
    
    mutating func addDescriptor(_ cbDescriptor: CBDescriptor) {
        guard let service = cbDescriptor.characteristic?.service, let characteristic = cbDescriptor.characteristic else { return }
        
        guard let serviceIndex = services.enumerated().first(where: { $0.element.id == service.uuid.uuidString })?.offset else { return }
                
                
        guard let characteristicIndex = services[serviceIndex].characteristics.enumerated().first(where: { $0.element.id == characteristic.uuid.uuidString })?.offset else { return }
        
        let descriptor = Service.Characteristic.Descriptor(
            cbDescriptor: cbDescriptor,
            id: cbDescriptor.uuid.uuidString,
            name: D.find(by: cbDescriptor.uuid)?.name
        )
        
        services[serviceIndex].characteristics[characteristicIndex].descriptors.append(descriptor)
    }
}
