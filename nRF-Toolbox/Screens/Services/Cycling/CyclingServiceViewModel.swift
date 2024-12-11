//
//  CyclingServiceViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

// MARK: - CyclingServiceViewModel

final class CyclingServiceViewModel: ObservableObject {
    
    // MARK: Properties
    
    @Published private(set) var data: CyclingData = .zero
    @Published private(set) var travelDistance = Measurement<UnitLength>(value: 0, unit: .kilometers)
    @Published private(set) var totalTravelDistance = Measurement<UnitLength>(value: 0, unit: .kilometers)
    @Published private(set) var speed = Measurement<UnitSpeed>(value: 0, unit: .kilometersPerHour)
    @Published private(set) var gearRatio: Double = 1
    @Published private(set) var cadence: Int = 0
    
    @Published private(set) var wheelSize = Measurement<UnitLength>(value: 29.0, unit: .inches)
    private var wheelCircumference: Double {
        2 * .pi * self.wheelSize.converted(to: .meters).value
    }
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cscMeasurement: CBCharacteristic!
    private var cscFeature: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "CyclingServiceViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(peripheral: Peripheral, cyclingService: CBService) {
        self.peripheral = peripheral
        self.service = cyclingService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
    
    // MARK: discoverCharacteristics()
    
    func discoverCharacteristics() async throws {
        log.debug(#function)
        let serviceCharacteristics: [Characteristic] = [.cscMeasurement, .cscFeature]
        let discoveredCharacteristics: [CBCharacteristic]
        discoveredCharacteristics = try await peripheral.discoverCharacteristics(serviceCharacteristics.map(\.uuid), for: service).firstValue
        
        for characteristic in discoveredCharacteristics {
            switch characteristic.uuid {
            case .cscMeasurement:
                self.cscMeasurement = characteristic
                log.debug("Found CSC Measurement Characteristic.")
            case .cscFeature:
                self.cscFeature = characteristic
                log.debug("Found CSC Feature Characteristic.")
            default:
                break
            }
        }
        
        guard cscMeasurement != nil, cscFeature != nil else {
            throw CriticalError.noMandatoryCharacteristics
        }
    }
    
    // MARK: startListening()
    
    func startListening() async throws {
        log.debug(#function)
        let cyclingFeatures = try await peripheral.readValue(for: cscFeature).tryMap { data in
            guard let data else {
                throw CriticalError.noData
            }
            return CyclingFeatures(flags: RegisterValue(data[0]))
        }
        .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: { CriticalError.timeout })
        .firstValue
        
        log.debug("Detected \(cyclingFeatures)")
        peripheral.listenValues(for: cscMeasurement)
            .compactMap { try? CyclingData($0) }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    self.log.debug("Finished!")
                case .failure(let error):
                    self.log.error("Error: \(error.localizedDescription)")
                }
            } receiveValue: { [unowned self] update in
                if let speedUpdate = update.speed(data, wheelCircumference: wheelCircumference) {
                    self.speed = speedUpdate
                }
                if let travelUpdate = update.distance(data, wheelCircumference: wheelCircumference) {
                    self.travelDistance = travelUpdate
                }
                if let totalDistanceUpdate = update.travelDistance(with: wheelCircumference) {
                    self.totalTravelDistance = totalDistanceUpdate
                }
                if let cadenceUpdate = update.cadence(data) {
                    self.cadence = cadenceUpdate
                }
                if let ratioUpdate = update.gearRatio(data) {
                    self.gearRatio = ratioUpdate
                }
                
                self.data = update
            }
            .store(in: &cancellables)
        
        // Enable Notifications
        log.debug("Enabling Cycling Speed & Cadence Notifications...")
        _ = try await peripheral.setNotifyValue(true, for: cscMeasurement).firstValue
    }
}

private extension CBUUID {
    static let cscMeasurement = CBUUID(characteristic: .cscMeasurement)
    static let cscFeature = CBUUID(characteristic: .cscFeature)
}

// MARK: - SupportedServiceViewModel

extension CyclingServiceViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        do {
            try await discoverCharacteristics()
            try await startListening()
        }
        catch let error {
            log.error("Error \(error.localizedDescription)")
            // TODO: Later, I guess.
        }
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}
