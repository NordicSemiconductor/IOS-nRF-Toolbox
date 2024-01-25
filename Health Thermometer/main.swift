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

/**
You can find example of the Health Thermometer peripheral here: TODO add link
*/

let cbPeripheral = try await scanAndConnect(to: "99027DE5-3248-5D9B-55DA-616266D395DF")

let peripheral = Peripheral(peripheral: cbPeripheral)

let services = try await peripheral.discoverServices(serviceUUIDs: nil).firstValue

print("ATTRIBUTE TABLE")
for service in services {
    guard let s = Service.find(by: service.uuid) else { continue }
    print("|-- \(s.name)")
    
    let characteristics = try await peripheral.discoverCharacteristics(nil, for: service).firstValue
    for characteristic in characteristics {
        guard let c = Characteristic.find(by: characteristic.uuid) else { continue }
        print("|---- \(c.name)")
        
        let descriptors = try await peripheral.discoverDescriptors(for: characteristic).firstValue
        for descriptor in descriptors {
            guard let d = Descriptor.find(by: descriptor.uuid) else { continue }
            print("|------ \(d.name)")
        }
    }
}

print("DEVICE INFORMATION:")
let deviceInfoService = (peripheral.peripheral.services?.first(where: { $0.uuid.uuidString == Service.deviceInformation.uuidString }))!
let deviceInfo = try await readDeviceInformation(from: deviceInfoService, peripheral: peripheral)
print(deviceInfo)

print("TEMPERATURE")
let temperatureService = (peripheral.peripheral.services?.first(where: { $0.uuid.uuidString == Service.healthThermometer.uuidString }))!
let tmCharacteristic = (temperatureService.characteristics?.first(where: { $0.uuid.uuidString == Characteristic.temperatureMeasurement.uuidString }))!
_ = try await peripheral.setNotifyValue(true, for: tmCharacteristic).firstValue

for try await t in peripheral.listenValues(for: tmCharacteristic).values {
    let temp = TemperatureMeasurement(data: t)
    print(temp)
}
