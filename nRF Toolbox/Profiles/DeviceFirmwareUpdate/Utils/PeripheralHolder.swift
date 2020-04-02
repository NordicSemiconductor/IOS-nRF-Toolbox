//
//  DFUBluetoothManager.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol PeripheralConnectionCallback: class {
    func peripheralWasSelected(_ peripheral: Peripheral)
}

class PeripheralHolder: NSObject, ConnectionViewControllerDelegate {
    private (set) var peripheral: Peripheral!
    weak var callback: PeripheralConnectionCallback?
    
    func requestConnection(to peripheral: Peripheral) {
        self.peripheral = peripheral
        callback?.peripheralWasSelected(peripheral)
    }
}
