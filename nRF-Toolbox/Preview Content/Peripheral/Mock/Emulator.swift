//
//  Emulator.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock
import CoreBluetoothMock_Collection

public struct BluetoothEmulation {
    static let shared = BluetoothEmulation()
    
    private let rscs = RunningSpeedAndCadence()
    
    public func simulateState() {
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
    }
    
    public func simulatePeripherals() {
        CBMCentralManagerMock.simulatePeripherals([blinky, hrm, rscs.peripheral, weightScale])
    }
}
