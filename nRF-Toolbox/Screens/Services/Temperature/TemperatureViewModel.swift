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
    
    @Published private(set) var data: [Int]
    
    // MARK: init
    
    init(peripheral: Peripheral, temperatureService: CBService) {
        self.peripheral = peripheral
        self.service = temperatureService
        self.cancellables = Set<AnyCancellable>()
        self.data = []
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
            .compactMap { data in
                TemperatureMeasurement(data)
            }
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    log.debug("Finished listening to Characteristic values.")
                case .failure(let error):
                    log.error("Encountered Error: \(error.localizedDescription)")
                }
            } receiveValue: { [unowned self] newValue in
                
//                if newValue.date.timeIntervalSince1970 - scrolPosition.timeIntervalSince1970 < CGFloat(visibleDomain + 5) || data.isEmpty {
//                    scrolPosition = Date()
//                }
//    
//                data.append(newValue)
//    
//                if data.count > capacity {
//                    data.removeFirst()
//                }
//    
//                let min = (data.min { $0.heartRate < $1.heartRate }?.heartRate ?? 40)
//                let max  = (data.max { $0.heartRate < $1.heartRate }?.heartRate ?? 140)
//    
//                lowest = min - 5
//                highest = max + 5
            }
            .store(in: &cancellables)
    }
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
}

// MARK: - TemperatureMeasurement

struct TemperatureMeasurement {
    
    let timestamp: Date
    
    init?(_ data: Data) {
        self.timestamp = .now
    }
}
