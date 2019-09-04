//
//  ScannedPeripheral.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScannedPeripheral: Equatable {
    
    let peripheral: CBPeripheral
    var rssi: Int32
    
    init(with peripheral: CBPeripheral, RSSI rssi:Int32 = 0) {
        self.peripheral = peripheral
        self.rssi = rssi
    }

    var name: String {
        return peripheral.name ?? "No name"
    }
    
    var isConnected: Bool {
        return peripheral.state == .connected
    }
}

func ==(lhs: ScannedPeripheral, rhs: ScannedPeripheral) -> Bool {
    return lhs.peripheral == rhs.peripheral
        && lhs.isConnected == rhs.isConnected
        && lhs.rssi == rhs.rssi
}
