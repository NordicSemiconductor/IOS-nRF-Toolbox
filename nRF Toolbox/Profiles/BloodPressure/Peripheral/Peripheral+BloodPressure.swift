//
//  Peripheral+BloodPressure.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth

extension PeripheralDescription {
    static let bloodPressure = PeripheralDescription(uuid: CBUUID.Profile.bloodPressureMonitor, services: [.battery, .measurement])
}

private extension PeripheralDescription.Service {
    static let measurement = PeripheralDescription.Service(uuid: CBUUID.Service.bloodPressureMonitor, characteristics: [
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.BloodPressure.measurement, properties: .notify(true)),
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.BloodPressure.intermediateCuff, properties: .notify(true))
    ])
}
