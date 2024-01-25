//
//  Scanner.swift
//  scanner
//
//  Created by Nick Kibysh on 25/01/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth
import Foundation
import iOS_BLE_Library

public func scanAndConnect(to uuidString: String) async throws -> CBPeripheral {
    let central = CentralManager()
    
    // Wait until CentralManager is in PowerON state
    _ = try await central.stateChannel.first(where: { $0 == .poweredOn }).firstValue
    
    let scanResultPublisher = central.scanForPeripherals(withServices: nil)
        .filter { $0.name != nil }
    
    var alreadyDiscovered: [ScanResult] = []
    
    for try await scanResult in scanResultPublisher.values {
        // Filter already discovered devices
        if !alreadyDiscovered.contains(where: { $0.peripheral.identifier == scanResult.peripheral.identifier }) {
            print("\(scanResult.name!): \(scanResult.peripheral.identifier.uuidString)")
            alreadyDiscovered.append(scanResult)
            
            if scanResult.peripheral.identifier.uuidString == uuidString {
                return try await central.connect(scanResult.peripheral).firstValue
            }
        }
    }
    
    fatalError("no peripheral discovered")
}
