//
//  Peripheral+HeartRate.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth

extension Peripheral {
    static let heartRateSensor = Peripheral(uuid: CBUUID.Profile.heartRateSensor, services: [.battery, .heartRateMeasurement])
}

private extension Peripheral.Service {
    static let heartRateMeasurement = Peripheral.Service(uuid: CBUUID.Service.heartRateSensor, characteristics: [
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.HeartRate.measurement, action: .notify(true)),
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.HeartRate.location, action: .notify(true))
    ])
}
