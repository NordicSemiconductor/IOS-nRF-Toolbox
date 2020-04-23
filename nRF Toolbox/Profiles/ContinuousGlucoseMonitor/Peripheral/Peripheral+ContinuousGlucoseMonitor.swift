//
// Created by Nick Kibysh on 21/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

private extension CBUUID {
    static let feature = CBUUID(hex: 0x2AA8)
    static let measurement = CBUUID(hex: 0x2AA7)
    static let sessionRunTime = CBUUID(hex: 0x2AAB)
    static let sessionStartTime = CBUUID(hex: 0x2AAA)
    static let specificOpsControlPoint = CBUUID(hex: 0x2AAC)
    static let status = CBUUID(hex: 0x2AA9)
    static let measurementContext = CBUUID(hex: 0x2A34)
    static let recordAccessPoint = CBUUID(hex: 0x2A52)
}

extension PeripheralDescription {
    static let continuousGlucoseMonitor = PeripheralDescription(uuid: CBUUID(hex: 0x181F), services: [.battery, .continuousGlucoseMonitor], mandatoryServices: [CBUUID(hex: 0x181F)],
        mandatoryCharacteristics: [
            .feature,
    .measurement,
    .sessionRunTime,
    .sessionStartTime,
    .specificOpsControlPoint,
    .status,
    .measurementContext,
    .recordAccessPoint
        ])
}

private extension PeripheralDescription.Service {
    static let continuousGlucoseMonitor = PeripheralDescription.Service(uuid: CBUUID(hex: 0x181F), characteristics: [.feature, .measurement, .sessionRunTime, .sessionStartTime, .specificOpsControlPoint, .status])
}

private extension PeripheralDescription.Service.Characteristic {
    static let feature = PeripheralDescription.Service.Characteristic(uuid: .feature, properties: .read)
    static let measurement = PeripheralDescription.Service.Characteristic(uuid: .measurement, properties: .notify(true))
    static let sessionRunTime = PeripheralDescription.Service.Characteristic(uuid: .sessionRunTime, properties: .read)
    static let sessionStartTime = PeripheralDescription.Service.Characteristic(uuid: .sessionStartTime, properties: .read)
    static let specificOpsControlPoint = PeripheralDescription.Service.Characteristic(uuid: .specificOpsControlPoint, properties: .read)
    static let status = PeripheralDescription.Service.Characteristic(uuid: .status, properties: .read)
    static let measurementContext = PeripheralDescription.Service.Characteristic(uuid: .measurementContext, properties: .read)
    static let recordAccessPoint = PeripheralDescription.Service.Characteristic(uuid: .recordAccessPoint, properties: .read)
}

