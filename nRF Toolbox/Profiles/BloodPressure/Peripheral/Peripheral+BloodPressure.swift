//
//  Peripheral+BloodPressure.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth

extension Peripheral {
    static let bloodPressure = Peripheral(uuid: CBUUID.Profile.bloodPressureMonitor, services: [.battery, .measurement])
}

private extension Peripheral.Service {
    static let measurement = Peripheral.Service(uuid: CBUUID.Service.bloodPressureMonitor, characteristics: [
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.BloodPressure.measurement, properties: .notify(true)),
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.BloodPressure.intermediateCuff, properties: .notify(true))
    ])
}
