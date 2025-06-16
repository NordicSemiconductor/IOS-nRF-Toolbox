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
    
    @Published var wheelSize = Measurement<UnitLength>(value: 29.0, unit: .inches).converted(to: .centimeters)
    private func wheelLength() -> Measurement<UnitLength> {
        Measurement<UnitLength>(value: self.wheelSize.converted(to: .meters).value * .pi,
                                unit: .meters)
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
            .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: {
                CriticalError.timeout
            })
        .firstValue
        
        log.debug("Detected \(cyclingFeatures)")
        peripheral.listenValues(for: cscMeasurement)
            .compactMap { [log] in
                log.debug("Received \($0.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) bytes.")
                return try? CyclingData($0)
            }
            .sink { [log] completion in
                switch completion {
                case .finished:
                    log.debug("Finished!")
                case .failure(let error):
                    log.error("Error: \(error.localizedDescription)")
                }
            } receiveValue: { update in
                Task { @MainActor [weak self] in
                    self?.update(from: update)
                }
            }
            .store(in: &cancellables)
        
        // Enable Notifications
        log.debug("Enabling Cycling Speed & Cadence Notifications...")
        _ = try await peripheral.setNotifyValue(true, for: cscMeasurement).firstValue
    }
    
    // MARK: update(from:)
    
    @MainActor
    private func update(from newData: CyclingData) {
        log.debug("Parsed valid update Data.")
        if let speedUpdate = newData.speed(data, wheelLength: wheelLength()) {
            self.speed = speedUpdate
        }
        if let travelUpdate = newData.distance(data, wheelLength: wheelLength()) {
            self.travelDistance = travelUpdate
        }
        if let totalDistanceUpdate = newData.travelDistance(with: wheelLength()) {
            self.totalTravelDistance = totalDistanceUpdate
        }
        if let cadenceUpdate = newData.cadence(data) {
            self.cadence = cadenceUpdate
        }
        if let ratioUpdate = newData.gearRatio(data) {
            self.gearRatio = ratioUpdate
        }
        
        let wheelData = newData.wheelData ?? data.wheelData
        let crankData = newData.crankData ?? data.crankData
        self.data = CyclingData(wheelData: wheelData ?? .zero, crankData: crankData ?? .zero)
    }
}

private extension CBUUID {
    static let cscMeasurement = CBUUID(characteristic: .cscMeasurement)
    static let cscFeature = CBUUID(characteristic: .cscFeature)
}

// MARK: - SupportedServiceViewModel

extension CyclingServiceViewModel: SupportedServiceViewModel {
    
    // MARK: attachedView
    
    var attachedView: SupportedServiceAttachedView {
        return .cycling(self)
    }
    
    // MARK: onConnect()
    
    func onConnect() async {
        log.debug(#function)
        do {
            try await discoverCharacteristics()
            try await startListening()
        }
        catch let error {
            log.error("Error \(error.localizedDescription)")
            // TODO: Later, I guess.
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
}
