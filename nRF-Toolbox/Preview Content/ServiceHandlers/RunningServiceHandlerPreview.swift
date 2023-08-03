//
//  RunningServiceHandlerPreview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

class RunningServiceHandlerPreview: RunningServiceHandler {
    
    override var measurement: RSCMeasurement? {
        get {
            RSCMeasurement(
                data: Data(),
                flags: .all,
                instantaneousSpeed: Measurement<UnitSpeed>.init(value: 10.0, unit: .kilometersPerHour),
                instantaneousCadence: 2,
                instantaneousStrideLength: Measurement<UnitLength>.init(value: 1.1, unit: .meters),
                totalDistance: Measurement<UnitLength>.init(value: 10.1, unit: .kilometers)
            )
        }
        set {
            
        }
    }
    
    init?() {
        super.init(
            peripheral: Peripheral(
                peripheral: CBMPeripheralPreview(runningSpeedCadenceSensor),
                delegate: ReactivePeripheralDelegate()
            ),
            service: CBMServiceMock(
                type: CBMUUID(string: Service.runningSpeedAndCadence.uuidString),
                primary: true
            )
        )
    }
    
    override func prepare() async throws {
        
    }
    
    override func enableMeasurement() {
        
    }
}
