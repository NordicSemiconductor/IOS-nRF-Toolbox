//
//  CBUUID+Ext.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 31/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database

extension CBMUUID {
    static let rscMeasurement = CBMUUID(string: Characteristic.RscMeasurement.rscMeasurement.uuidString)
    static let rscFeature = CBMUUID(string: Characteristic.RscFeature.rscFeature.uuidString)
    static let sensorLocation = CBMUUID(string: Characteristic.SensorLocation.sensorLocation.uuidString)
    static let scControlPoint = CBMUUID(string: Characteristic.ScControlPoint.scControlPoint.uuidString)
}
