//
//  RunningServiceHandlerPreview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

class RunningServiceHandlerPreview: RunningServiceHandler {
    init?() {
        super.init(
            peripheral: Peripheral(
                peripheral: CBMPeripheralPreview(blinky),
                delegate: ReactivePeripheralDelegate()
            ),
            service: CBMServiceMock(
                type: CBMUUID(string: Service.Nordicsemi.LEDAndButton.nordicLEDAndButtonService.uuidString),
                primary: true
            )
        )
        
        self.measurement = RSCMeasurement(
            data: Data(),
            flags: RSCMeasurementFlags(value: 0xffff),
            instantaneousSpeed: Measurement<UnitSpeed>.init(value: 10.0, unit: .kilometersPerHour),
            instantaneousCadence: 2,
            instantaneousStrideLength: Measurement<UnitLength>.init(value: 1.1, unit: .meters),
            totalDistance: Measurement<UnitLength>.init(value: 10.1, unit: .kilometers)
        )
    }
    
    override func prepare() async throws {
        
    }
    
    override func enableMeasurement() {
        
    }
}
