//
//  DFUPeripheralSelector.swift
//  Pods
//
//  Created by Mostafa Berg on 20/06/16.
//
//

import CoreBluetooth

/// The default selector. Returns the first device with DFU Service UUID in the advrtising packet.
public class DFUPeripheralSelector : NSObject, DFUPeripheralSelectorDelegate {

    private var isSecureDFU : Bool

    init(secureDFU : Bool) {
        isSecureDFU = secureDFU
        super.init()
    }

    public func select(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> Bool {
        return true
    }
    
    public func filterBy() -> [CBUUID]? {
        if self.isSecureDFU {
            return [SecureDFUService.UUID]
        } else {
            return [LegacyDFUService.UUID]
        }
    }
}

