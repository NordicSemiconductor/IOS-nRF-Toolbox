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
        @Published var selectedSensorLocation: UInt8 = SensorLocation.other.rawValue
        
        @Published var updateLocationDisabled = true
        
        var hudState: HUDState?
        
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
    
    func updateLocationSection() async {
        await updateAvailableLocations()
        await updateCurrentSensorLocation()
    }
    
    func updateAvailableLocations() async {
        await wrappError {
            self.availableLocation = try await self.handler.readAvailableLocations()
        }
    }
    
    func updateCurrentSensorLocation() async {
        await wrappError {
            self.currentSensorLocation = try await self.handler.readSensorLocation().rawValue
            self.selectedSensorLocation = self.currentSensorLocation
        }
    }
    
    func writeNewSensorLocation() async {
        await wrappError {
            try await handler.writeSensorLocation(newLocation: SensorLocation(rawValue: selectedSensorLocation)!)
            
            hudState?.show(title: "New Sensor Location: \(SensorLocation(rawValue: selectedSensorLocation)!.description)", systemImage: "sensor")
        }
    }
    
    func resetDistance() async {
        await wrappError {
            try await handler.writeCumulativeValue(newDistance: Measurement(value: 0, unit: .meters))
            
            hudState?.show(title: "Distance was reset", systemImage: "ruler")
        }
    }
    
    func startCalibration() async {
        await wrappError {
            try await handler.startCalibration()
            hudState?.show(title: "Calibration procedure was started", systemImage: "slider.horizontal.2.gobackward")
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
