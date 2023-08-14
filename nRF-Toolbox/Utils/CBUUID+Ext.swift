//
//  CBUUID+Ext.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 31/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database

extension CBMUUID {
    convenience init(characteristic: Characteristic) {
        self.init(string: characteristic.uuidString)
    }
    
    convenience init(service: Service) {
        self.init(string: service.uuidString)
    }
    
    convenience init(descriptor: Descriptor) {
        self.init(string: descriptor.uuidString)
    }
}
