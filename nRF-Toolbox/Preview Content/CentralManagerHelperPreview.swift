//
//  CentralManagerHelperPreview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 20/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock

class CentralManagerHelperPreview: CentralManagerHelper {
    static let sharedPreview = CentralManagerHelperPreview.shared
    
    private let mocDevices: Bool
    
    override var peripheralManagers: [DeviceDetailsViewModel] {
        get {
            if mocDevices {
                return [
                    DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(hrm)),
                    DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(runningSpeedCadenceSensor))
                ]
            } else {
                return Array<DeviceDetailsViewModel>()
            }
        }
        set {
            
        }
    }
    
    init(generateDevices: Bool = false) {
        self.mocDevices = generateDevices
    }
}
