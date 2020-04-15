//
// Created by Nick Kibysh on 05/11/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBUUID {
    static let immediateAlertService = CBUUID(hex: 0x1802)
    static let linkLossService = CBUUID(hex: 0x1803)
    static let proximityAlertLevelCharacteristic = CBUUID(hex: 0x2A06)
    static let txPowerLevelService = CBUUID(hex: 0x1804)
    static let txPowerLevelCharacteristic = CBUUID(hex: 0x2A07)
}

extension PeripheralDescription {
    static let proximity = PeripheralDescription(uuid: .linkLossService, services: [
        .battery, .immediateAlert, .linkLoss, .txPower
    ], requiredServices: [.immediateAlertService])
}

private extension PeripheralDescription.Service {
    static let immediateAlert = PeripheralDescription.Service(uuid: .immediateAlertService, characteristics: [.proximityAlertLevel])
    static let linkLoss = PeripheralDescription.Service(uuid: .linkLossService, characteristics: [.proximityAlertLevel])
    static let txPower = PeripheralDescription.Service(uuid: .txPowerLevelService, characteristics: [.txPowerLevel])
}

private extension PeripheralDescription.Service.Characteristic {
    static let proximityAlertLevel = PeripheralDescription.Service.Characteristic(uuid: .proximityAlertLevelCharacteristic, properties: nil)
    static let txPowerLevel = PeripheralDescription.Service.Characteristic(uuid: .txPowerLevelCharacteristic, properties: .read)
}
