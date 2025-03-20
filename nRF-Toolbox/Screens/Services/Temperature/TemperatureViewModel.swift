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
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "TemperatureViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published private(set) var measurement: TemperatureMeasurement
    
    // MARK: init
    
    init(peripheral: Peripheral, temperatureService: CBService) {
        self.peripheral = peripheral
        self.service = temperatureService
        self.cancellables = Set<AnyCancellable>()
        self.measurement = TemperatureMeasurement(Data())
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension TemperatureViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        log.debug(#function)
        do {
            let characteristics: [Characteristic] = [.temperatureMeasurement]
            
            let measurementCharacteristics = try await peripheral.discoverCharacteristics(characteristics.map(\.uuid), for: service)
                    .timeout(1, scheduler: DispatchQueue.main)
                    .firstValue
            
            for characteristic in measurementCharacteristics where characteristic.uuid == Characteristic.temperatureMeasurement.uuid {
                listenTo(characteristic)
                _ = try await peripheral.setNotifyValue(true, for: characteristic).firstValue
            }
        }
        catch {
            log.error(error.localizedDescription)
        }
    }
    
    func listenTo(_ characteristic: CBCharacteristic) {
        peripheral.listenValues(for: characteristic)
            .map { data in
                TemperatureMeasurement(data)
            }
            .sink(to: \.measurement, in: self, assigningInCaseOfError: TemperatureMeasurement(Data()))
            .store(in: &cancellables)
    }
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
}
