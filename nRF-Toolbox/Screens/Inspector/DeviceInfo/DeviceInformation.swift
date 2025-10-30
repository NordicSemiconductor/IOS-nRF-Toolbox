//
//  DeviceInformation.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 06/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Combine
import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - DeviceInformation

public struct DeviceInformation: CustomDebugStringConvertible {
    
    // MARK: CharacteristicInfo
    
    struct CharacteristicInfo: Identifiable {
        var id: String { name }
        var name: String
        var value: String
    }

    // MARK: Properties
    
    public var manufacturerName: String?
    public var modelNumber: String?
    public var serialNumber: String?
    public var hardwareRevision: String?
    public var firmwareRevision: String?
    public var softwareRevision: String?
    public var systemID: String?
    public var ieee11073: String?
    
    // MARK: init
    
    public init(_ characteristics: [CBCharacteristic], peripheral: Peripheral) async throws {
        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.manufacturerNameString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                manufacturerName = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.modelNumberString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                modelNumber = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.serialNumberString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                serialNumber = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.hardwareRevisionString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                hardwareRevision = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.firmwareRevisionString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                firmwareRevision = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.softwareRevisionString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                softwareRevision = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.systemId.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                systemID = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.ieee11073_20601RegulatoryCertificationDataList.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                ieee11073 = String(data: data, encoding: .utf8)
            }
        }
    }
    
    // MARK: debugDescription
    
    public var debugDescription: String {
        var s = ""
        if let manufacturerName {
            s += "Manufacturer: \(manufacturerName)\n"
        }
        if let modelNumber {
            s += "Model Number: \(modelNumber)\n"
        }
        if let serialNumber {
            s += "Serial Number: \(serialNumber)\n"
        }
        if let hardwareRevision {
            s += "Hardware Revision: \(hardwareRevision)\n"
        }
        if let firmwareRevision {
            s += "Firmware Revision: \(firmwareRevision)\n"
        }
        if let softwareRevision {
            s += "Software Revision: \(softwareRevision)\n"
        }
        if let systemID {
            s += "System ID: \(systemID)\n"
        }
        if let ieee11073 {
            s += "IEEE 11073: \(ieee11073)\n"
        }
        return s
    }

    // MARK: characteristics
    
    var characteristics: [CharacteristicInfo] {
        var c = [CharacteristicInfo]()
        if let manufacturerName {
            c.append(CharacteristicInfo(name: "Manufacturer", value: manufacturerName))
        }
        if let modelNumber {
            c.append(CharacteristicInfo(name: "Model Number", value: modelNumber))
        }
        if let serialNumber {
            c.append(CharacteristicInfo(name: "Serial Number", value: serialNumber))
        }
        if let hardwareRevision {
            c.append(CharacteristicInfo(name: "Hardware Revision", value: hardwareRevision))
        }
        if let firmwareRevision {
            c.append(CharacteristicInfo(name: "Firmware Revision", value: firmwareRevision))
        }
        if let softwareRevision {
            c.append(CharacteristicInfo(name: "Software Revision", value: softwareRevision))
        }
        if let systemID {
            c.append(CharacteristicInfo(name: "System ID", value: systemID))
        }
        if let ieee11073 {
            c.append(CharacteristicInfo(name: "IEEE 11073", value: ieee11073))
        }
        return c
    }
}
