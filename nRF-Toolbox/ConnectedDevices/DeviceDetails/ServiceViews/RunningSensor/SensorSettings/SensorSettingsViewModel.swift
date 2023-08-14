//
//  SensorSettingsViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 08/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock_Collection
import iOS_BLE_Library
import iOS_Bluetooth_Numbers_Database
import CoreBluetoothMock
import Combine

extension SensorSettings {
    @MainActor
    class ViewModel: ObservableObject {
        private var cancelables = Set<AnyCancellable>()
        
        @Published var error: ReadableError? = nil {
            didSet {
                showError = true
            }
        }
        @Published var showError: Bool = false
        @Published var availableLocation: [RunningSpeedAndCadence.SensorLocation] = []
        @Published var supportedFeatures: RunningSpeedAndCadence.RSCFeature = .none
        @Published var currentSensorLocation: UInt8 = SensorLocation.other.rawValue
        
        let handler: RunningServiceHandler
        
        init(handler: RunningServiceHandler) {
            self.handler = handler
            Task {
                await updateFeature()
            }
        }
    }
}

extension SensorSettings.ViewModel {
    func updateFeature() async {
        await wrappError {
            self.supportedFeatures = try await handler.readSupportedFeatures()
        }
    }
    
    func updateAvailableLocations() async {
        await wrappError {
            self.availableLocation = try await self.handler.readAvailableLocations()
        }
    }
    
    func updateCurrentSensorLocation() async {
        await wrappError {
            self.currentSensorLocation = try await self.handler.readSensorLocation().rawValue
        }
    }
    
    private func wrappError(_ wrapper: () async throws -> ()) async {
        do {
            try await wrapper()
        } catch let e {
            self.error = ReadableError(error: e)
        }
    }
}

extension SensorSettings.ViewModel {
    
}

#if DEBUG

extension SensorSettings {
    class MockViewModel: ViewModel {
        init() {
            super.init(handler: MockRunningServiceHandler())
        }
    }
}

#endif
