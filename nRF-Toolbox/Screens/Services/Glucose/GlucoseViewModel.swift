//
//  GlucoseViewModel.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 6/6/25.
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

// MARK: - GlucoseViewModel

final class GlucoseViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var peripheralSessionTime: Date!
    private var cbGlucoseMeasurement: CBCharacteristic!
    private var cbRACP: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "GlucoseViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var records = [CGMSMeasurement]()
    @Published var scrollPosition = 0
    
    // MARK: init
    
    init(peripheral: Peripheral, glucoseService: CBService) {
        self.peripheral = peripheral
        self.service = glucoseService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension GlucoseViewModel: SupportedServiceViewModel {
    
    // MARK: attachedView
    
    var attachedView: SupportedServiceAttachedView {
        return .glucose(self)
    }
    
    // MARK: onConnect()
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .glucoseMeasurement, .glucoseFeature,
            .recordAccessControlPoint
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        cbGlucoseMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.glucoseMeasurement.uuid)
        cbRACP = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.recordAccessControlPoint.uuid)
        
        guard let cbGlucoseMeasurement else {
            return
        }
        
        do {
            let now = Date.now
            
            
            
        } catch {
            log.error(error.localizedDescription)
            onDisconnect()
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        peripheralSessionTime = nil
        cbGlucoseMeasurement = nil
        cbRACP = nil
        cancellables.removeAll()
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let glucoseService = CBUUID(service: .glucose)
}
