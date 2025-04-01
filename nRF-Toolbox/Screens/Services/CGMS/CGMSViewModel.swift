//
//  CGMSViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 1/4/25.
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

// MARK: - CGMSViewModel

final class CGMSViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "CGMSViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(peripheral: Peripheral, cgmsService: CBService) {
        self.peripheral = peripheral
        self.service = cgmsService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension CGMSViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        log.debug(#function)
        
    }
    
    func listenTo(_ characteristic: CBCharacteristic) {
        
    }
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let continuousGlucoseMonitoringtService = CBUUID(service: .continuousGlucoseMonitoring)
}
