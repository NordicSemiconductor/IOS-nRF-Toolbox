//
//  Emulator.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock

public struct BluetoothEmulation {
    
    static let shared = BluetoothEmulation()
    
    private let cscs = CSCSCBMPeripheralSpecDelegate()
    private let rscs = RSCSCBMPeripheralSpecDelegate()
    private let heartRate = HeartRateCBMPeripheralSpecDelegate()
    private let glucose = GLSCBMPeripheralSpecDelegate()
    private let bloodPressure = BPSCBMPeripheralSpecDelegate()
    private let healthThermometer = HTSCBMPeripheralSpecDelegate()
    private let cgms = CGMSCBMPeripheralSpecDelegate()
    private let uart = UARTCBMPeripheralSpecDelegate()
    private let aggregated = AggregatedPeripheralSpecDelegate(delegates: [
        CSCSCBMPeripheralSpecDelegate(),
        RSCSCBMPeripheralSpecDelegate(),
        HeartRateCBMPeripheralSpecDelegate(),
        GLSCBMPeripheralSpecDelegate(),
        BPSCBMPeripheralSpecDelegate(),
        HTSCBMPeripheralSpecDelegate(),
        CGMSCBMPeripheralSpecDelegate(),
        UARTCBMPeripheralSpecDelegate()
    ])
    
    public func simulateState() {
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
    }
    
    public func simulatePeripherals() {
        CBMCentralManagerMock.simulatePeripherals([
            aggregated.peripheral,
            cscs.peripheral,
            rscs.peripheral,
            heartRate.peripheral,
            glucose.peripheral,
            bloodPressure.peripheral,
            healthThermometer.peripheral,
            cgms.peripheral,
            uart.peripheral,
            blinky
        ])
    }
    
    public func simulateDisconnect() {
        rscs.peripheral.simulateDisconnection()
        heartRate.peripheral.simulateDisconnection()
    }
}
