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
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var bpsMeasurement: CBCharacteristic!
    private var bpsFlags: CBCharacteristic!
    private var cuffMeasurement: CBCharacteristic!
    private lazy var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "BloodPressureViewModel",
                                subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published private(set) var currentValue: BloodPressureMeasurement?
    @Published private(set) var features: BitField<BloodPressureMeasurement.Feature>?
    @Published private(set) var currentCuffValue: CuffPressureMeasurement?
    
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
    
    // MARK: attachedView
    
    var attachedView: SupportedServiceAttachedView {
        return .bloodPressure(self)
    }
    
    // MARK: onConnect()
    
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .bloodPressureMeasurement, .bloodPressureFeature, .intermediateCuffPressure
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        bpsMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.bloodPressureMeasurement.uuid)
        bpsFlags = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.bloodPressureFeature.uuid)
        cuffMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.intermediateCuffPressure.uuid)
        
        do {
            if let bpsMeasurement {
                log.debug("Found Blood Pressure Measurement.")
                if let initialValue = bpsMeasurement.value {
                    currentValue = try? BloodPressureMeasurement(data: initialValue)
                    log.debug("Obtained initial Blood Pressure Measurement.")
                }
                let bpsEnable = try await peripheral.setNotifyValue(true, for: bpsMeasurement).firstValue
                log.debug("BPS Measurement.setNotifyValue(true): \(bpsEnable)")
                
                listenTo(bpsMeasurement)
            }
            
            if let bpsFlags {
                log.debug("Found Blood Pressure Feature.")
                let featureData = try await peripheral.readValue(for: bpsFlags).firstValue
                if let featureData, featureData.canRead(UInt16.self, atOffset: 0) {
                    let featureFlags = UInt(featureData.littleEndianBytes(atOffset: 0, as: UInt16.self))
                    self.features = BitField<BloodPressureMeasurement.Feature>(featureFlags)
                    print(features.nilDescription)
                }
            }
            
            if let cuffMeasurement {
                log.debug("Found Intermediate Cuff Pressure Measurement.")
                if let initialValue = cuffMeasurement.value {
                    currentCuffValue = try? CuffPressureMeasurement(data: initialValue)
                    log.debug("Obtained initial Intermediate Cuff Pressure Measurement.")
                }
            }
        } catch {
            log.debug(error.localizedDescription)
            onDisconnect()
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        bpsMeasurement = nil
        cancellables.removeAll()
    }
}

extension BloodPressureViewModel {
    
    // MARK: listen(to:)
    
    func listenTo(_ bpsCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: bpsCharacteristic)
            .compactMap { [log] data -> BloodPressureMeasurement? in
                log.debug("Received Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) (\(data.count) bytes)")
                do {
                    return try BloodPressureMeasurement(data: data)
                } catch {
                    log.error("Error parsing data: \(error.localizedDescription)")
                    return nil
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [log] _ in
                log.debug("Completion")
            }, receiveValue: { [weak self] newValue in
                self?.currentValue = newValue
            })
            .store(in: &cancellables)
    }
}
