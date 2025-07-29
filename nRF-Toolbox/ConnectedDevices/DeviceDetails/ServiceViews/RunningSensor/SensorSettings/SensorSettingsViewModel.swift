//
//  SensorSettingsViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 08/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock
import Combine

// MARK: - SensorSettingsViewModel

@MainActor
final class SensorSettingsViewModel: ObservableObject {
    
    @Published var error: ReadableError? = nil {
        didSet {
            showError = true
        }
    }
    @Published var showError: Bool = false
    @Published var availableLocation: [RunningSpeedAndCadence.SensorLocation] = []
    @Published var supportedFeatures = BitField<RunningSpeedAndCadence.RSCFeature>()
    @Published var currentSensorLocation: UInt8 = SensorLocation.other.rawValue
    @Published var selectedSensorLocation: UInt8 = SensorLocation.other.rawValue
    
    @Published var updateLocationDisabled = true
    
    let handler: RunningServiceHandler
    
    private let log = NordicLog(category: "SensorSettingsViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    private lazy var cancellables = Set<AnyCancellable>()
    
    init(handler: RunningServiceHandler) {
        self.handler = handler
        Task {
            await updateFeature()
        }
        log.debug(#function)
    }
    
    deinit {
        log.debug(#function)
    }
    
}

extension SensorSettingsViewModel {
    
    func updateFeature() async {
        log.debug(#function)
        await wrapError { [unowned self] in
            supportedFeatures = try await handler.readSupportedFeatures()
        }
    }
    
    func updateLocationSection() async {
        log.debug(#function)
        await updateAvailableLocations()
        await updateCurrentSensorLocation()
    }
    
    func updateAvailableLocations() async {
        log.debug(#function)
        await wrapError { [unowned self] in
            availableLocation = try await handler.readAvailableLocations()
        }
    }
    
    func updateCurrentSensorLocation() async {
        log.debug(#function)
        await wrapError { [unowned self] in
            currentSensorLocation = try await handler.readSensorLocation().rawValue
            selectedSensorLocation = currentSensorLocation
        }
    }
    
    func writeNewSensorLocation() async {
        log.debug(#function)
        await wrapError { [unowned self] in
            try await handler.writeSensorLocation(newLocation: SensorLocation(rawValue: selectedSensorLocation)!)
        }
    }
    
    func resetDistance() async {
        log.debug(#function)
        await wrapError { [unowned self] in
            try await handler.writeCumulativeValue(newDistance: Measurement(value: 0, unit: .meters))
        }
    }
    
    func startCalibration() async {
        log.debug(#function)
        await wrapError { [unowned self] in
            try await handler.startCalibration()
        }
    }
    
    private func wrapError(_ wrapper: () async throws -> ()) async {
        do {
            try await wrapper()
        } catch let error {
            self.error = ReadableError(error)
        }
    }
}
