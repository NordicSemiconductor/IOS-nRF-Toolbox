//
//  HealthThermometerViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - HealthThermometerViewModel

final class HealthThermometerViewModel: SupportedServiceViewModel, ObservableObject {
    
    // MARK: Private Properties
    
    private let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "TemperatureViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    // MARK: Properties
    
    @Published private(set) var measurement: TemperatureMeasurement?
    
    // MARK: init
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.characteristics = characteristics
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
  
    // MARK: description
    
    var description: String {
        "Health Thermometer"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return HealthThermometerView()
            .environmentObject(self)
    }
    
    // MARK: onConnect()
    
    func onConnect() async {
        log.debug(#function)
        do {
            let characteristics: [Characteristic] = [.temperatureMeasurement]
            
            let measurementCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
                characteristics.contains { $0.uuid == cbChar.uuid }
            }
            
            for characteristic in measurementCharacteristics where characteristic.uuid == Characteristic.temperatureMeasurement.uuid {
                listenTo(characteristic)
                _ = try await peripheral.setNotifyValue(true, for: characteristic).firstValue
            }
        }
        catch {
            log.error(error.localizedDescription)
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
    
    func listenTo(_ characteristic: CBCharacteristic) {
        peripheral.listenValues(for: characteristic)
            .map { data in
                try? TemperatureMeasurement(data)
            }
            .sink(to: \.measurement, in: self, assigningInCaseOfError: nil)
            .store(in: &cancellables)
    }
}
