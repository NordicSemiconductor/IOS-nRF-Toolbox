//
//  main.swift
//  Health Thermometer
//
//  Created by Nick Kibysh on 25/01/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

import OSLog

let l = Logger(subsystem: "com.nordicsemi.bles-playground", category: "playground")

/**
You can find example of the Health Thermometer peripheral here: TODO add link
*/

/**
To discover the UUID of the peripheral you want to connect to, run the app and copy the UUID from the console. 
*/

let deviceUUIDString = "9D3F50D4-0273-1129-1F15-3143EAFDB299"
let cbPeripheral = try await scanAndConnect(to: deviceUUIDString)

let peripheral = Peripheral(peripheral: cbPeripheral)

let services = try await peripheral.discoverServices(serviceUUIDs: nil).firstValue

l.info("ATTRIBUTE TABLE")
for service in services {
    guard let s = Service.find(by: service.uuid) else { continue }
    l.debug("|-- \(s.name) \(s.uuidString)")
    
    let characteristics = try await peripheral.discoverCharacteristics(nil, for: service).firstValue
    for characteristic in characteristics {
        guard let c = Characteristic.find(by: characteristic.uuid) else { continue }
        l.debug("|---- \(c.name) \(c.uuidString)")
        
        let descriptors = try await peripheral.discoverDescriptors(for: characteristic).firstValue
        for descriptor in descriptors {
            guard let d = Descriptor.find(by: descriptor.uuid) else { continue }
            l.debug("|------ \(d.name) \(c.uuidString)")
        }
    }
}

if let userData = services.first(where: { $0.uuid == Service.userData.uuid }) {
    l.debug("Discovered UserData service")
    if let characteristic = userData.characteristics?.first(where: { $0.uuid == Characteristic.firstName.uuid }) {
        l.debug("Discovered FirstName characteristic")
        if let descriptor = characteristic.descriptors?.first(where: { $0.uuid == Descriptor.gattCharacteristicUserDescription.uuid }) {
            l.debug("Discovered User descriptor")
            do {
                
                let data = "Hello".data(using: .ascii)!
                try await peripheral.writeValue(data, for: descriptor).firstValue
                
                let value = try await peripheral.readValue(for: descriptor).firstValue
                
                if let d = value as? String {
                    l.debug("Response: \(d)")
                } else {
                    l.warning("Received Value \(value.debugDescription)")
                }
                
            } catch {
                l.error("\(error.localizedDescription)")
            }
        } else {
            l.error("No Required Descriptor")
        }
    } else {
        l.error("No Required Characteristic")
    }
} else {
    l.error("No Required Service")
}

l.info("BATTERY")

if let batteryService = (peripheral.peripheral.services?.first(where: { $0.uuid == Service.batteryService.uuid })) {
    do {
        let batteryServiceParser = BatteryServiceParser(batteryService: batteryService)
        
        let descriptor = batteryServiceParser.batteryLevelDescriptor!
        
        try! await peripheral.writeValue(Data([1]), for: descriptor).firstValue
        
        let data = try await peripheral.readValue(for: descriptor).firstValue
        l.debug("\(data.debugDescription)")
         
    } catch {
        l.error("\(error.localizedDescription)")
    }
}

