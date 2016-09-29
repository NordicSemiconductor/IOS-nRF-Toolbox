//
//  DFUPeripheralSelector.swift
//  Pods
//
//  Created by Mostafa Berg on 20/06/16.
//
//

import CoreBluetooth

/// The default selector. Returns the first device with DFU Service UUID in the advrtising packet.
open class DFUPeripheralSelector : NSObject, DFUPeripheralSelectorDelegate {

    fileprivate var isSecureDFU : Bool

    init(secureDFU : Bool) {
        isSecureDFU = secureDFU
        super.init()
    }

    open func select(_ peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> Bool {
        return true
    }
    
    open func filterBy() -> [CBUUID]? {
        if self.isSecureDFU {
            return [SecureDFUService.UUID]
        } else {
            return [LegacyDFUService.UUID]
        }
    }
}

