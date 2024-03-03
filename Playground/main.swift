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
import Combine

import OSLog

let l = Logger(subsystem: "com.nordicsemi.bles-playground", category: "playground")

/**
You can find example of the Health Thermometer peripheral here: TODO add link
*/

/**
To discover the UUID of the peripheral you want to connect to, run the app and copy the UUID from the console. 
*/

let deviceUUIDString = "99027DE5-3248-5D9B-55DA-616266D395DF"
let cbPeripheral = try await scanAndConnect(to: deviceUUIDString)

let peripheral = Peripheral(peripheral: cbPeripheral)

let services = try await peripheral.discoverServices(serviceUUIDs: nil).firstValue

var cancelable = Set<AnyCancellable>()

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
/*
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
*/
l.info("BATTERY")

if let batteryService = (peripheral.peripheral.services?.first(where: { $0.uuid == Service.batteryService.uuid })) {
    do {
        let batteryServiceParser = BatteryServiceParser(batteryService: batteryService)
        _ = try await peripheral.setNotifyValue(true, for: batteryServiceParser.batteryLevelCharacteristic).firstValue
        
        peripheral.listenValues(for: batteryServiceParser.batteryLevelCharacteristic)
            .sink { completion in
                switch completion {
                case .finished: l.info("Battery Level completed sending values")
                case .failure(let error): l.error("Battery Level completed with failure: \(error.localizedDescription)")
                }
            } receiveValue: { batteryData in
                l.debug("\(batteryData[0])")
            }
            .store(in: &cancelable)

    } catch {
        l.error("\(error.localizedDescription)")
    }
}

l.info("HEALTH THERMOMETER")
if let htService = (peripheral.peripheral.services?.first(where: { $0.uuid == Service.healthThermometer.uuid })) {
    do {
        let parser = HealthThermometerServiceParser(htService: htService)
        
        _ = try await peripheral.setNotifyValue(true, for: parser.temperatureMeasurementCharacteristic).firstValue
        
        let stream = peripheral.listenValues(for: parser.temperatureMeasurementCharacteristic)
            .map { TemperatureMeasurement(data: $0) }
        
        for try await m in stream.values {
            l.debug("Measurement: \(m.debugDescription )")
        }
    }
}

