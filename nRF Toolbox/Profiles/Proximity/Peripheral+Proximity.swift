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

extension Peripheral {
    static let proximity = Peripheral(uuid: .linkLossService, services: [
        .battery, .immediateAlert, .linkLoss, .txPower
    ])
}

private extension Peripheral.Service {
    static let immediateAlert = Peripheral.Service(uuid: .immediateAlertService, characteristics: [.proximityAlertLevel])
    static let linkLoss = Peripheral.Service(uuid: .linkLossService, characteristics: [.proximityAlertLevel])
    static let txPower = Peripheral.Service(uuid: .txPowerLevelService, characteristics: [.txPowerLevel])
}

private extension Peripheral.Service.Characteristic {
    static let proximityAlertLevel = Peripheral.Service.Characteristic(uuid: .proximityAlertLevelCharacteristic, properties: nil)
    static let txPowerLevel = Peripheral.Service.Characteristic(uuid: .txPowerLevelCharacteristic, properties: .read)
}