//
//  DFUBluetoothManager.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol DFUConnectionCallback: class {
    func peripheralWasSelected(_ peripheral: Peripheral)
}

class DFUBluetoothManager: NSObject, ConnectionViewControllerDelegate {
    private (set) var peripheral: Peripheral!
    weak var callback: DFUConnectionCallback?
    
    func requestConnection(to peripheral: Peripheral) {
        self.peripheral = peripheral
        callback?.peripheralWasSelected(peripheral)
    }
}
