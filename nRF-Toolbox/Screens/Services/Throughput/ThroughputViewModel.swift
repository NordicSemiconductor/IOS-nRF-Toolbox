//
//  ThroughputViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 27/1/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

final class ThroughputViewModel: ObservableObject {
    
    internal static let throughputService = Service(name: "Throughput Service", identifier: "com.nordicsemi.service.throughput", uuidString: "0483DADD-6C9D-6CA9-5D41-03AD4FFF4ABB", source: "nordic")
    
    internal static let throughputCharacteristic = Characteristic(
        name: "Throughput", identifier: "com.nordicsemi.characteristic.throughput",
        uuidString: "1524", source: "nordic")
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "ThroughputViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(_ peripheral: Peripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension ThroughputViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        do {
            
        }
        catch let error {
            log.error("Error \(error.localizedDescription)")
        }
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}

// MARK: - CBUUID

internal extension CBUUID {
    
    static let throughputService = CBUUID(service: ThroughputViewModel.throughputService)
    
    static let throughputCharacteristic = CBUUID(characteristic: ThroughputViewModel.throughputCharacteristic)
}
