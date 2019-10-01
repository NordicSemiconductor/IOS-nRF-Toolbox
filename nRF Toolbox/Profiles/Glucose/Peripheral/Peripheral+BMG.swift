//
//  Peripheral+BMG.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Peripheral {
    static let bloodGlucoseMonitor = Peripheral(uuid: CBUUID.Service.bloodGlucoseMonitor, services: [
        .battery, .bloodGlucoseMonitor
    ])
}

private extension Peripheral.Service {
    static let bloodGlucoseMonitor = Peripheral.Service(uuid: CBUUID.Service.bloodGlucoseMonitor, characteristics: [
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.BloodGlucoseMonitor.glucoseMeasurement, action: .notify(true)),
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.BloodGlucoseMonitor.glucoseMeasurementContext, action: .notify(true)),
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.BloodGlucoseMonitor.recordAccessControlPoint, action: .notify(true))
    ])
}
