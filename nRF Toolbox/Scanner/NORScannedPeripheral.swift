//
//  NORScannedPeripheral.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

@objc class NORScannedPeripheral: NSObject {
    
    var peripheral  : CBPeripheral
    var RSSI        : Int
    var isConnected : Bool
    
    init(withPeripheral aPeripheral: CBPeripheral, andRSSI anRSSI:Int, andIsConnected aConnectionStatus: Bool) {
        peripheral = aPeripheral
        RSSI = anRSSI
        isConnected = aConnectionStatus
    }

    func name()->String{
        let peripheralName = peripheral.name
        if peripheral.name == nil {
            return "No name"
        }else{
            return peripheralName!
        }
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        let otherPeripheral : NORScannedPeripheral = object as! NORScannedPeripheral
        return peripheral == otherPeripheral.peripheral
    }
}