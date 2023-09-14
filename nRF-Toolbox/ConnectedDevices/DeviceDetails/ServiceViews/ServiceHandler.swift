//
//  ServiceHandler.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import SwiftUI

@MainActor
class ServiceHandler: Identifiable {
    let peripheral: Peripheral
    let service: CBService
    
    nonisolated var id: String { service.uuid.uuidString }
    
    @Published private (set) var state: CBPeripheralState = .connecting
    
    var name: String { Service.find(by: id)?.name ?? "Unknown Service" }
    var image: Image { Image(systemName: "circle.hexagongrid.circle")  }
    
    init?(peripheral: Peripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service
        
        guard peripheral.peripheral.services?.contains(where: { $0.uuid == service.uuid }) == true else {
            return nil
        }
    }
    
    func manageConnection() {
        peripheral.peripheralStateChannel
            .assign(to: &$state)
    }
}
