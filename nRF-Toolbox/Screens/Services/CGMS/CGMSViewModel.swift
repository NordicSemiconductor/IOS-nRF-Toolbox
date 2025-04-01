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
        let characteristics: [Characteristic] = [
            .cgmMeasurement, .recordAccessControlPoint,
            .cgmSpecificOpsControlPoint, .cgmStatus, .cgmFeature
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        guard let cbCgmMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmMeasurement.uuid),
              let cbRacpMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.recordAccessControlPoint.uuid),
              let cbSOCPMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmSpecificOpsControlPoint.uuid) else {
            return
        }
        
        do {
            listenTo(cbCgmMeasurement)
            let cgmEnable = try await peripheral.setNotifyValue(true, for: cbCgmMeasurement).firstValue
            log.debug("CGMS Measurement.setNotifyValue(true): \(cgmEnable)")
            
//            guard result else {
//                // TODO: throw Error
//            }
            let socpEnable = try await peripheral.setNotifyValue(true, for: cbSOCPMeasurement).firstValue
            log.debug("CGMS SOCP.setNotifyValue(true): \(socpEnable)")
            
            let racpEnable = try await peripheral.setNotifyValue(true, for: cbRacpMeasurement).firstValue
            log.debug("CGMS RACP.setNotifyValue(true): \(racpEnable)")
        } catch {
            log.error(error.localizedDescription)
            onDisconnect()
        }
        
//        [00:00:28.884,521] <inf> cgms: CGMS Measurement: notification enabled
//        [00:00:29.044,525] <inf> cgms: CGMS SOCP: indication enabled
//        [00:00:29.204,528] <inf> cgms: CGMS RACP: indication enabled
//        [00:00:39.964,294] <inf> cgms: RACP: work submission done
//        [00:00:40.044,799] <inf> cgms: RACP: work submission done
    }
    
    func listenTo(_ characteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: characteristic)
            .map { data in
                print("Received \(data.count) bytes")
            }
            .sink(receiveCompletion: { _ in
                print("Completion")
            }, receiveValue: { _ in
                print("Received Value")
            })
            .store(in: &cancellables)
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
