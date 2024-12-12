//
//  TemperatureViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

// MARK: - TemperatureViewModel

final class TemperatureViewModel: ObservableObject {
    
    // MARK: Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "TemperatureViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(peripheral: Peripheral, temperatureService: CBService) {
        self.peripheral = peripheral
        self.service = temperatureService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension TemperatureViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        do {
            
        }
        catch {
            // TODO: Later, I guess.
        }
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}
