//
//  CBMCharacteristicPropertiesExt.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 28/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//
import Combine
import CoreBluetoothMock
import Foundation
import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

extension CBMCharacteristic {
    func hasNotyfyingProperties() -> Bool {
        let requiredProperties: CBCharacteristicProperties = [.notify, .indicate, .indicateEncryptionRequired, .notifyEncryptionRequired]

        return properties.isSubset(of: requiredProperties)
    }
}
