//
//  Peripheral+Temperature.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Peripheral {
    static let healthTemperature = Peripheral(uuid: CBUUID.Profile.healthTemperature, services: [.measurement])
}

private extension Peripheral.Service {
    static let measurement = Peripheral.Service(uuid: CBUUID.Service.healthTemperature, characteristics: [
        Characteristic(uuid: CBUUID.Characteristics.HealthTemperature.measurement, action: .notify(true))
    ])
}
