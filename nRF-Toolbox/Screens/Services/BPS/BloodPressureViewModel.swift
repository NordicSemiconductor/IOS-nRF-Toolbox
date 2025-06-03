//
//  BloodPressureViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/6/25.
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

// MARK: - BloodPressureViewModel

@MainActor
final class BloodPressureViewModel: ObservableObject {
    
    // MARK: Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var bpsMeasurement: CBCharacteristic!
    private lazy var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "BloodPressureViewModel",
                                subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(peripheral: Peripheral, bpsService: CBService) {
        self.peripheral = peripheral
        self.service = bpsService
        log.debug(#function)
    }
    
    // MARK: deinit
    
    deinit {
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension BloodPressureViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .bloodPressureMeasurement, .bloodPressureFeature
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        bpsMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.bloodPressureMeasurement.uuid)
        guard let bpsMeasurement else { return }
        log.debug("Found Blood Pressure Measurement.")
        do {
            if let initialValue = bpsMeasurement.value {
                log.debug("Obtained initial Blood Pressure Measurement.")
                let measurement = try BloodPressureCharacteristic(data: initialValue)
            }
        } catch {
            log.debug(error.localizedDescription)
            onDisconnect()
        }
        
//        switch characteristic.uuid {
//        case CBUUID.Characteristics.BloodPressure.measurement:
//            do {
//                let bloodPressureCharacteristic = try BloodPressureCharacteristic(data: value)
//                bloodPressureSection.update(with: bloodPressureCharacteristic)
//                heartRateSection.update(with: bloodPressureCharacteristic)
//                dateTimeSection.update(with: bloodPressureCharacteristic)
//                
//                tableView.reloadData()
//            } catch let error {
//                displayErrorAlert(error: error)
//            }
//
//        case CBUUID.Characteristics.BloodPressure.intermediateCuff:
//            do {
//                let cuffCharacteristic = try CuffPressureCharacteristic(data: value)
//                cuffPressureSection.update(with: cuffCharacteristic)
//            } catch let error {
//                displayErrorAlert(error: error)
//            }
//
//            tableView.reloadData()
//        default:
//            super.didUpdateValue(for: characteristic)
//        }
    }
    
    func onDisconnect() {
        log.debug(#function)
        bpsMeasurement = nil
        cancellables.removeAll()
    }
}
