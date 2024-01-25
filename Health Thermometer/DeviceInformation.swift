//
//  DeviceInformation.swift
//  Health Thermometer
//
//  Created by Nick Kibysh on 25/01/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth
import Foundation
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

public struct DeviceInformation: CustomDebugStringConvertible {
    public var manufacturerName: String?
    public var modelNumber: String?
    public var serialNumber: String?
    public var hardwareRevision: String?
    public var firmwareRevision: String?
    public var softwareRevision: String?
    public var systemID: String?
    public var ieee11073: String?
    
    public var debugDescription: String {
        var s = ""
        if let manufacturerName = manufacturerName {
            s += "Manufacturer Name: \(manufacturerName)\n"
        }
        if let modelNumber = modelNumber {
            s += "Model Number: \(modelNumber)\n"
        }
        if let serialNumber = serialNumber {
            s += "Serial Number: \(serialNumber)\n"
        }
        if let hardwareRevision = hardwareRevision {
            s += "Hardware Revision: \(hardwareRevision)\n"
        }
        if let firmwareRevision = firmwareRevision {
            s += "Firmware Revision: \(firmwareRevision)\n"
        }
        if let softwareRevision = softwareRevision {
            s += "Software Revision: \(softwareRevision)\n"
        }
        if let systemID = systemID {
            s += "System ID: \(systemID)\n"
        }
        if let ieee11073 = ieee11073 {
            s += "IEEE 11073: \(ieee11073)\n"
        }
        return s
    }
}

public func readDeviceInformation(from service: CBService, peripheral: Peripheral) async throws -> DeviceInformation {
    var di = DeviceInformation()
    
    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.manufacturerNameString.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.manufacturerName = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.modelNumberString.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.modelNumber = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.serialNumberString.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.serialNumber = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.hardwareRevisionString.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.hardwareRevision = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.firmwareRevisionString.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.firmwareRevision = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.softwareRevisionString.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.softwareRevision = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.systemId.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.systemID = String(data: data, encoding: .utf8)
        }
    }

    if let c = service.characteristics?.first(where: { $0.uuid == CBUUID(string: Characteristic.ieee11073_20601RegulatoryCertificationDataList.uuidString) }) {
        if let data = try await peripheral.readValue(for: c).firstValue {
            di.ieee11073 = String(data: data, encoding: .utf8)
        }
    }
    
    return di
}
