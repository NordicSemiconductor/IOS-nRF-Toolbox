//
//  CuffPressureViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - CuffPressureViewModel

@MainActor
final class CuffPressureViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var cuffMeasurement: CBCharacteristic!
    private lazy var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "CuffPressureViewModel",
                                subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published private(set) var currentValue: CuffPressureMeasurement?
    
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

extension CuffPressureViewModel: SupportedServiceViewModel {
    
    // MARK: attachedView
    
    var attachedView: SupportedServiceAttachedView {
        return .cuffPressure(self)
    }
    
    // MARK: onConnect()
    
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .intermediateCuffPressure
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        cuffMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.intermediateCuffPressure.uuid)
        
        do {
            if let cuffMeasurement {
                log.debug("Found Intermediate Cuff Pressure Measurement \(cuffMeasurement.uuid)")
                let cuffData = try? await peripheral.readValue(for: cuffMeasurement).firstValue
                if let cuffData {
                    currentValue = try? CuffPressureMeasurement(data: cuffData)
                    log.debug("Obtained initial Intermediate Cuff Pressure Measurement.")
                }
                
                let cuffEnable = try await peripheral.setNotifyValue(true, for: cuffMeasurement).firstValue
                log.debug("Cuff Measurement.setNotifyValue(true): \(cuffEnable)")
                
                listenTo(cuffMeasurement)
            }
        } catch {
            log.debug(error.localizedDescription)
            onDisconnect()
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        cuffMeasurement = nil
        cancellables.removeAll()
    }
}

extension CuffPressureViewModel {
    
    // MARK: listenTo(:)
    
    func listenTo(_ cuffCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: cuffCharacteristic)
            .compactMap { [log] data -> CuffPressureMeasurement? in
                log.debug("Received Cuff Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) (\(data.count) bytes)")
                do {
                    return try CuffPressureMeasurement(data: data)
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
