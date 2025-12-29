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
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - BloodPressureViewModel

final class BloodPressureViewModel: @MainActor SupportedServiceViewModel, ObservableObject {
    
    // MARK: Private Properties
    
    private let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    
    private var bpsMeasurement: CBCharacteristic!
    private var bpsFlags: CBCharacteristic!
    private lazy var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "BloodPressureViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published private(set) var currentValue: BloodPressureMeasurement?
    @Published private(set) var features = BitField<BloodPressureMeasurement.Feature>()
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    // MARK: init
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.characteristics = characteristics
        log.debug(#function)
    }
    
    // MARK: deinit
    
    deinit {
        log.debug(#function)
    }
    
    // MARK: description
    
    var description: String {
        "Blood Pressure"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return BloodPressureView()
            .environmentObject(self)
    }
    
    // MARK: onConnect()
    @MainActor
    func onConnect() async {
        log.debug(#function)
        do {
            try await initializeCharacteristics()
        } catch {
            log.error("Error \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    @MainActor
    func initializeCharacteristics() async throws {
        let characteristics: [Characteristic] = [
            .bloodPressureMeasurement, .bloodPressureFeature
        ]
        let cbCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
            characteristics.contains { $0.uuid == cbChar.uuid }
        }
        
        bpsMeasurement = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.bloodPressureMeasurement.uuid)
        bpsFlags = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.bloodPressureFeature.uuid)
        
        guard let bpsMeasurement, let bpsFlags else {
            throw ServiceError.noMandatoryCharacteristic
        }
        
        if let initialValue = bpsMeasurement.value {
            currentValue = try? BloodPressureMeasurement(data: initialValue)
            log.debug("Obtained initial Blood Pressure Measurement.")
        }
        
        listenTo(bpsMeasurement)
        let bpsEnable = try await peripheral.setNotifyValue(true, for: bpsMeasurement).firstValue
        guard bpsEnable else { throw ServiceError.notificationsNotEnabled }
        log.debug("BPS Measurement.setNotifyValue(true): \(bpsEnable)")
        
        log.debug("Found Blood Pressure Feature.")
        let featureData = try await peripheral.readValue(for: bpsFlags).firstValue
        if let featureData, featureData.canRead(UInt16.self, atOffset: 0) {
            let featureFlags = UInt(featureData.littleEndianBytes(atOffset: 0, as: UInt16.self))
            self.features = BitField<BloodPressureMeasurement.Feature>(featureFlags)
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
    
    // MARK: listenTo(:)
    
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
