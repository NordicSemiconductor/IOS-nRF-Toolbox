//
//  DeviceInformation.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 06/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database

public struct DeviceInformation: CustomDebugStringConvertible {
    struct Characteristic: Identifiable {
        var id: String { name }
        var name: String
        var value: String
    }

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

    var characteristics: [Characteristic] {
        var c = [Characteristic]()
        if let manufacturerName = manufacturerName {
            c.append(Characteristic(name: "Manufacturer Name", value: manufacturerName))
        }
        if let modelNumber = modelNumber {
            c.append(Characteristic(name: "Model Number", value: modelNumber))
        }
        if let serialNumber = serialNumber {
            c.append(Characteristic(name: "Serial Number", value: serialNumber))
        }
        if let hardwareRevision = hardwareRevision {
            c.append(Characteristic(name: "Hardware Revision", value: hardwareRevision))
        }
        if let firmwareRevision = firmwareRevision {
            c.append(Characteristic(name: "Firmware Revision", value: firmwareRevision))
        }
        if let softwareRevision = softwareRevision {
            c.append(Characteristic(name: "Software Revision", value: softwareRevision))
        }
        if let systemID = systemID {
            c.append(Characteristic(name: "System ID", value: systemID))
        }
        if let ieee11073 = ieee11073 {
            c.append(Characteristic(name: "IEEE 11073", value: ieee11073))
        }
        return c
    }
}
