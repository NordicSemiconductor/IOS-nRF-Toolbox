//
//  CBPeripheralState+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreBluetooth

extension CBPeripheralState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connectiong"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        @unknown default:
            return "Unknown"
        }
    }
}
