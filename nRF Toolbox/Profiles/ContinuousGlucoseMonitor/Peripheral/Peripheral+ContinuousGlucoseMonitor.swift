//
// Created by Nick Kibysh on 21/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Peripheral {
    static let continuousGlucoseMonitor = Peripheral(uuid: CBUUID(hex: 0x181F), services: [.battery, .continuousGlucoseMonitor])
}

private extension Peripheral.Service {
    static let continuousGlucoseMonitor = Peripheral.Service(uuid: CBUUID(hex: 0x181F), characteristics: [.feature, .measurement, .sessionRunTime, .sessionStartTime, .specificOpsControlPoint, .status])
}

private extension Peripheral.Service.Characteristic {
    static let feature = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2AA8), properties: .read)
    static let measurement = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2AA7), properties: .notify(true))
    static let sessionRunTime = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2AAB), properties: .read)
    static let sessionStartTime = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2AAA), properties: .read)
    static let specificOpsControlPoint = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2AAC), properties: .read)
    static let status = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2AA9), properties: .read)
    static let measurementContext = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2A34), properties: .read)
    static let recordAccessPoint = Peripheral.Service.Characteristic(uuid: CBUUID(hex: 0x2A52), properties: .read)
}

