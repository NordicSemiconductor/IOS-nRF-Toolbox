//
//  Peripheral+Running.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Peripheral {
    static let runningSpeedCadenceSensor = Peripheral(uuid: CBUUID.Profile.runningSpeedCadenceSensor, services: [.battery, .speedCadence])
}

private extension Peripheral.Service {
    static let speedCadence = Peripheral.Service(uuid: CBUUID.Service.runningSpeedCadenceSensor, characteristics: [
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.Running.measurement, properties: .notify(true))
    ])
}
