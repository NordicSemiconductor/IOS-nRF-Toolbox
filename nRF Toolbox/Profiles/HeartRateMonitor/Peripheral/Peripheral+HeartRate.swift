//
//  Peripheral+HeartRate.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth

extension PeripheralDescription {
    static let heartRateSensor = PeripheralDescription(uuid: CBUUID.Profile.heartRateSensor, services: [.battery, .heartRateMeasurement], mandatoryServices: [CBUUID.Service.heartRateSensor], mandatoryCharacteristics: [CBUUID.Characteristics.HeartRate.measurement])
}

private extension PeripheralDescription.Service {
    static let heartRateMeasurement = PeripheralDescription.Service(uuid: CBUUID.Service.heartRateSensor, characteristics: [
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.HeartRate.measurement, properties: .notify(true)),
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.HeartRate.location, properties: .notify(true))
    ])
}
