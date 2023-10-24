//
//  AttributeTable.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database

protocol StringIdentifiable  {
    var identifier: String { get }
}

struct AttributeTable {
    private (set) var services: [Service] = []
    
    mutating func addService(_ cbService: CBService) {
        var service = Service(cbService: cbService)
        
        service.characteristics = cbService.characteristics?.map { cbch in
            var ch = Service.Characteristic(cbCharacteristic: cbch)
            
            ch.descriptors = cbch.descriptors?.map { cbd in
                Service.Characteristic.Descriptor(cbDescriptor: cbd)
            } ?? []
            
            return ch
        } ?? []
        
        services.replacedOrAppended(service, compareBy: \.identifier)
    }
    
    mutating func addCharacteristic(_ cbCharacteristic: CBCharacteristic) {
        guard let service = cbCharacteristic.service else {
            return
        }
        guard let serviceIndex = services.enumerated()
            .first(where: { $0.element.identifier == service.uuid.uuidString })?
            .offset else {
            return
        }
        
        var charateristic = Service.Characteristic(
            cbCharacteristic: cbCharacteristic
        )
        
        charateristic.descriptors = cbCharacteristic.descriptors?.map { cbd in
            Service.Characteristic.Descriptor(
                cbDescriptor: cbd
            )
        } ?? []
        
        services[serviceIndex].characteristics.replacedOrAppended(charateristic, compareBy: \.identifier)
    }
    
    mutating func addDescriptor(_ cbDescriptor: CBDescriptor) {
        guard let service = cbDescriptor.characteristic?.service, let characteristic = cbDescriptor.characteristic else { return }
        
        guard let serviceIndex = services.enumerated().first(where: { $0.element.identifier == service.uuid.uuidString })?.offset else { return }
                
        guard let characteristicIndex = services[serviceIndex].characteristics.enumerated().first(where: { $0.element.identifier == characteristic.uuid.uuidString })?.offset else { return }
        
        let descriptor = Service.Characteristic.Descriptor(
            cbDescriptor: cbDescriptor
        )
        
        services[serviceIndex].characteristics[characteristicIndex].descriptors.replacedOrAppended(descriptor, compareBy: \.identifier)
    }
    
    var attributeList: [Attribute] {
        var list: [Attribute] = []
        
        for s in services {
            list.append(s)
            for c in s.characteristics {
                list.append(c)
                
                for d in c.descriptors {
                    list.append(d)
                }
            }
        }
        
        return list 
    }
}

extension AttributeTable {
    struct Service: Identifiable, StringIdentifiable, Equatable, Attribute {
        typealias S = iOS_Bluetooth_Numbers_Database.Service
        
        var uuidString: String { cbService.uuid.uuidString }
        
        let cbService: CBService
        let id: String
        let identifier: String
        let name: String
        var level: UInt { 1 }
        fileprivate (set) var characteristics: [Characteristic] = []
        
        init(cbService: CBService, id: String, identifier: String, name: String, characteristics: [Characteristic]) {
            self.cbService = cbService
            self.id = id
            self.identifier = identifier
            self.name = name
            self.characteristics = characteristics
        }
        
        init(cbService: CBService, defaultName: String = "Unknown Service") {
            self.cbService = cbService
            self.id = "s" + cbService.uuid.uuidString
            self.identifier = cbService.uuid.uuidString
            self.name = S.find(by: cbService.uuid)?.name ?? defaultName
        }
    }
}

extension AttributeTable.Service {
    struct Characteristic: Identifiable, StringIdentifiable, Equatable, Attribute {
        
        typealias C = iOS_Bluetooth_Numbers_Database.Characteristic
        
        var uuidString: String {
            cbCharacteristic.uuid.uuidString
        }
        
        
        let cbCharacteristic: CBCharacteristic
        let id: String
        let identifier: String
        let name: String
        var level: UInt { 2 }
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
        
        init(cbCharacteristic: CBCharacteristic, id: String, identifier: String, name: String, descriptors: [Descriptor]) {
            self.cbCharacteristic = cbCharacteristic
            self.id = id
            self.identifier = identifier
            self.name = name
            self.descriptors = descriptors
        }
        
        init(cbCharacteristic: CBCharacteristic, defaultName: String = "Unknown Characteristic") {
            self.cbCharacteristic = cbCharacteristic
            self.id = ((cbCharacteristic.service?.uuid.uuidString).map { "s" + $0 } ?? "") + "c" + cbCharacteristic.uuid.uuidString
            self.identifier = cbCharacteristic.uuid.uuidString
            self.name = C.find(by: cbCharacteristic.uuid)?.name ?? defaultName
        }
    }
}

extension AttributeTable.Service.Characteristic {
    struct Descriptor: Identifiable, StringIdentifiable, Equatable, Attribute {
        typealias D = iOS_Bluetooth_Numbers_Database.Descriptor
        
        let cbDescriptor: CBDescriptor
        let id: String
        let identifier: String
        let name: String
        var level: UInt { 3 }
        
        var uuidString: String { cbDescriptor.uuid.uuidString }
        
        init(cbDescriptor: CBDescriptor, id: String, identifier: String, name: String) {
            self.cbDescriptor = cbDescriptor
            self.id = id
            self.identifier = identifier
            self.name = name
        }
        
        init(cbDescriptor: CBDescriptor, defaultName: String = "Unknown Descriptor") {
            self.cbDescriptor = cbDescriptor
            self.identifier = cbDescriptor.uuid.uuidString
            self.id = ((cbDescriptor.characteristic?.service?.uuid.uuidString).map { "s" + $0 } ?? "")
                + ((cbDescriptor.characteristic?.uuid.uuidString).map { "c" + $0 } ?? "")
                + "d" + cbDescriptor.uuid.uuidString
            
            self.name = D.find(by: cbDescriptor.uuid)?.name ?? defaultName
        }
    }
}

