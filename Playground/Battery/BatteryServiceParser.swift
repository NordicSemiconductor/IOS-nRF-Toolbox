//
//  BatteryServiceParser.swift
//  Playground
//
//  Created by Nick Kibysh on 26/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth
import iOS_Bluetooth_Numbers_Database

struct BatteryServiceParser {
    let batteryService: CBService
    
    // Characteristics 
    let batteryLevelCharacteristic: CBCharacteristic                    // Mandatory. Read. Notify (optional)
    var batteryLevelDescriptor: CBDescriptor?                           // C.1. Read 

    var batteryLevelStatusCharacteristic: CBCharacteristic?             // Optional. Read, Notify
    var estimatedServiceDateCharacteristic: CBCharacteristic?           // C.2. Read, Notify. Indicate (optional)
    var batteryCriticalStatusCharacteristic: CBCharacteristic?          // C.2. Read, Indicate
    var batteryEnergyStatusCharacteristic: CBCharacteristic?            // C.2. Read, Notify. Indicate (optional)
    var batteryTimeToFullCharacteristic: CBCharacteristic?              // C.2. Read, Notify. Indicate (optional)
    var batteryHealthCharacteristic: CBCharacteristic?                  // C.2. Read, Notify. Indicate (optional)
    var batteryHealthInformationCharacteristic: CBCharacteristic?       // C.3. Read, Indicate
    var batteryInformationCharacteristic: CBCharacteristic?             // C.2. Read, Indicate
    var manufacturerNameStringCharacteristic: CBCharacteristic?         // Optional. Read, Indicate
    var modelNumberStringCharacteristic: CBCharacteristic?              // Optional. Read, Indicate
    var serialNumberStringCharacteristic: CBCharacteristic?             // C.2. Read, Indicate

    // C.1: Mandatory if a device has more than one instance of Battery Service; otherwise optional.
    // C.2: Optional if the Battery Level Status characteristic is exposed; otherwise excluded.
    // C.3: Optional if the Battery Health Status characteristic is exposed; otherwise excluded.

    init(batteryService: CBService) {
        assert(batteryService.uuid == Service.batteryService.uuid, "Battery Service is expected")
        self.batteryService = batteryService

        batteryLevelCharacteristic = batteryService.characteristics!.first(where: { $0.uuid == Characteristic.batteryLevel.uuid })!
        batteryLevelDescriptor = batteryLevelCharacteristic.descriptors?.first(where: { $0.uuid == Descriptor.gattClientCharacteristicConfiguration.uuid })

        batteryLevelStatusCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryLevelState.uuid })
        /*
        estimatedServiceDateCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.est.uuid })
        batteryCriticalStatusCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryCriticalStatus.uuid })
        batteryEnergyStatusCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryEnergyStatus.uuid })
        batteryTimeToFullCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryTimeToFull.uuid })
        batteryHealthCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryHealth.uuid })
        batteryHealthInformationCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryHealthInformation.uuid })
        batteryInformationCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.batteryInformation.uuid })
         */
        manufacturerNameStringCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.manufacturerNameString.uuid })
        modelNumberStringCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.modelNumberString.uuid })
        serialNumberStringCharacteristic = batteryService.characteristics?.first(where: { $0.uuid == Characteristic.serialNumberString.uuid })
    }
    
    mutating func findCharacteristics() {
        
    }
}
