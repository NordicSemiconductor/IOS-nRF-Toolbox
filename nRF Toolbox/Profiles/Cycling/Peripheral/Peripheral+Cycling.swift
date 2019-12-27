//
//  Peripheral+Cycling.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension PeripheralDescription {
    static let cyclingSpeedCadenceSensor = PeripheralDescription(uuid: CBUUID.Profile.cyclingSpeedCadenceSensor, services: [
        .battery, .cyclingSpeedCadenceSensor
    ])
}

private extension PeripheralDescription.Service {
    static let cyclingSpeedCadenceSensor = PeripheralDescription.Service(uuid: CBUUID.Service.cyclingSpeedCadenceSensor, characteristics: [
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.CyclingSesnor.measurement, properties: .notify(true)),
    ])
}
