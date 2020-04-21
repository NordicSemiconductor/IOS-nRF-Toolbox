//
//  ProximityBluetoothManager.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 20.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth



class ProximityBluetoothManager: NSObject {
    private let peripheralDescription: PeripheralDescription = .proximity

    private var peripheralManager: CBPeripheralManager!
    private var centralManager: CBCentralManager!
    private var immediateAlertCharacteristic: CBCharacteristic!
    
    var errorHandler: ((Error) -> ())?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
}

extension ProximityBluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error {
            errorHandler?(e)
            return
        }
        
    }
}

extension ProximityBluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
}
