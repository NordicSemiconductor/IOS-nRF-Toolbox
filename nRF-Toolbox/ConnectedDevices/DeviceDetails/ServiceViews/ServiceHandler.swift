//
//  ServiceHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library

class ServiceHandler: Identifiable {
    let peripheral: Peripheral
    let service: CBService
    var id: String { service.uuid.uuidString }
    
    init?(peripheral: Peripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service
        
        guard peripheral.peripheral.services?.contains(where: { $0.uuid == service.uuid }) == true else {
            return nil
        }
    }
}
