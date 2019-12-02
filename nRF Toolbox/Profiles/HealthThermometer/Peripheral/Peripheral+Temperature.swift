//
//  Peripheral+Temperature.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension PeripheralDescription {
    static let healthTemperature = PeripheralDescription(uuid: CBUUID.Profile.healthTemperature, services: [.measurement])
}

private extension PeripheralDescription.Service {
    static let measurement = PeripheralDescription.Service(uuid: CBUUID.Service.healthTemperature, characteristics: [
        Characteristic(uuid: CBUUID.Characteristics.HealthTemperature.measurement, properties: .notify(true))
    ])
}
