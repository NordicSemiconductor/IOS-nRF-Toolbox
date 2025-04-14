//
//  UARTViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
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

// MARK: - UARTViewModel

final class UARTViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "UARTViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    // MARK: init
    
    init(peripheral: Peripheral, uartService: CBService) {
        self.peripheral = peripheral
        self.service = uartService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension UARTViewModel: SupportedServiceViewModel {
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        
    }
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let nordicsemiUART = CBUUID(service: .nordicsemiUART)
}
