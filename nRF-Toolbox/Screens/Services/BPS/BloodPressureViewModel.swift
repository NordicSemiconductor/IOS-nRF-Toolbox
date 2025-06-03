//
//  BloodPressureViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import iOS_BLE_Library_Mock
import iOS_Common_Libraries

// MARK: - BloodPressureViewModel

@MainActor
final class BloodPressureViewModel: ObservableObject {
    
    // MARK: Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
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
        // MARK: TODO
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}
