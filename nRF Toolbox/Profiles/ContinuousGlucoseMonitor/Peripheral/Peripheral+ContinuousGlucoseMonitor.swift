//
// Created by Nick Kibysh on 21/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension PeripheralDescription {
    static let continuousGlucoseMonitor = PeripheralDescription(uuid: CBUUID(hex: 0x181F), services: [.battery, .continuousGlucoseMonitor])
}

private extension PeripheralDescription.Service {
    static let continuousGlucoseMonitor = PeripheralDescription.Service(uuid: CBUUID(hex: 0x181F), characteristics: [.feature, .measurement, .sessionRunTime, .sessionStartTime, .specificOpsControlPoint, .status])
}

private extension PeripheralDescription.Service.Characteristic {
    static let feature = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2AA8), properties: .read)
    static let measurement = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2AA7), properties: .notify(true))
    static let sessionRunTime = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2AAB), properties: .read)
    static let sessionStartTime = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2AAA), properties: .read)
    static let specificOpsControlPoint = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2AAC), properties: .read)
    static let status = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2AA9), properties: .read)
    static let measurementContext = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2A34), properties: .read)
    static let recordAccessPoint = PeripheralDescription.Service.Characteristic(uuid: CBUUID(hex: 0x2A52), properties: .read)
}

