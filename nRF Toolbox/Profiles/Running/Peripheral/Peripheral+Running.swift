//
//  Peripheral+Running.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension PeripheralDescription {
    static let runningSpeedCadenceSensor = PeripheralDescription(uuid: CBUUID.Profile.runningSpeedCadenceSensor, services: [.battery, .speedCadence], mandatoryServices: [CBUUID.Service.runningSpeedCadenceSensor], mandatoryCharacteristics: [CBUUID.Characteristics.Running.measurement])
}

private extension PeripheralDescription.Service {
    static let speedCadence = PeripheralDescription.Service(uuid: CBUUID.Service.runningSpeedCadenceSensor, characteristics: [
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.Running.measurement, properties: .notify(true))
    ])
}
