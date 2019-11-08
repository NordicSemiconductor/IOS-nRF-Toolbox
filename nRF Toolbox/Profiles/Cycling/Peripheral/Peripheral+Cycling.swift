//
//  Peripheral+Cycling.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Peripheral {
    static let cyclingSpeedCadenceSensor = Peripheral(uuid: CBUUID.Profile.cyclingSpeedCadenceSensor, services: [
        .battery, .cyclingSpeedCadenceSensor
    ])
}

private extension Peripheral.Service {
    static let cyclingSpeedCadenceSensor = Peripheral.Service(uuid: CBUUID.Service.cyclingSpeedCadenceSensor, characteristics: [
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.CyclingSesnor.measurement, properties: .notify(true)),
    ])
}
