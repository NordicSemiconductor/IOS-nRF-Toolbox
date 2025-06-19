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

@MainActor
final class GlucoseViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cbGlucoseMeasurement: CBCharacteristic!
    private var cbRACP: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "GlucoseViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var allRecords = [GlucoseMeasurement]()
    @Published private(set) var firstRecord: GlucoseMeasurement?
    @Published private(set) var lastRecord: GlucoseMeasurement?
    private var request: CGMOperator?
    
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
//            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        cbGlucoseMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.glucoseMeasurement.uuid)
        cbRACP = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.recordAccessControlPoint.uuid)
        guard let cbGlucoseMeasurement else { return }
        
        do {
            let measurementDescriptors = try await peripheral
                .discoverDescriptors(for: cbGlucoseMeasurement)
//                .receive(on: RunLoop.main)
                .firstValue
            
            guard let measurementCCD = measurementDescriptors.first(where: \.uuid, isEqualsTo: Descriptor.gattClientCharacteristicConfiguration.uuid) else {
                throw CriticalError.cannotFindGlucoseMeasurementCCD
            }
                
            let glucoseNotificationsEnabled: Bool = try await peripheral.readValue(for: measurementCCD)
                .compactMap {
                    $0 as? Int
                }
                .firstValue > 0
            log.debug("GlucoseMeasurement.CCD.isNotifying: \(glucoseNotificationsEnabled)")
            
            if glucoseNotificationsEnabled {
                log.info("Glucose Measurement Notifications already enabled.")
            }
            
            let glucoseEnable = try await peripheral.setNotifyValue(true, for: cbGlucoseMeasurement)
                .timeout(1, scheduler: RunLoop.main)
                .receive(on: RunLoop.main)
                .firstValue
            log.debug("GlucoseMeasurement.setNotifyValue(true): \(glucoseEnable)")
            
            listenToMeasurements(cbGlucoseMeasurement)
        } catch {
            log.error(error.localizedDescription)
            onDisconnect()
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        cbGlucoseMeasurement = nil
        cbRACP = nil
        cancellables.removeAll()
    }
}

// MARK: API

extension GlucoseViewModel {
    
    // MARK: requestRecords()
    
    nonisolated
    func requestRecords(_ op: CGMOperator) {
        Task { @MainActor in
            guard let cbRACP else { return }
            log.debug(#function)
            do {
                request = op
                if request == .allRecords {
                    allRecords.removeAll()
                }
                
                // If we don't listen to RACP Response via Notification / Indication,
                // it'll restart, fail, or complain. Don't ask.
                let turnOnIndications = try await peripheral.setNotifyValue(true, for: cbRACP).firstValue
                log.debug("peripheral.setIndicate(true): \(turnOnIndications)")
                
                let writeData = Data([RACPOpCode.reportStoredRecords.rawValue, op.rawValue])
                
                log.debug("peripheral.listenToRACPRequest()")
                async let racpResult = try peripheral.listenValues(for: cbRACP).firstValue
                
                log.debug("peripheral.writeValueWithResponse(\(writeData.hexEncodedString(options: [.prepend0x, .upperCase])))")
                try await peripheral.writeValueWithResponse(writeData, for: cbRACP).firstValue
                
                let requestResult = try await racpResult
                log.debug("RACP Request Result: \(requestResult)")
                
                // Keep our nose clean by turning notifications back off.
                let turnOffIndications = try await peripheral.setNotifyValue(false, for: cbRACP).firstValue
                log.debug("peripheral.setIndicate(false): \(turnOffIndications)")
            } catch {
                log.error("\(#function) Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Private

private extension GlucoseViewModel {
    
    // MARK: listenToMeasurements()
    
    func listenToMeasurements(_ measurementCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: measurementCharacteristic)
            .compactMap { [log] data -> GlucoseMeasurement? in
                log.debug("Received Measurement Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) (\(data.count) bytes)")
                
                guard let parsed = GlucoseMeasurement(data) else {
                    log.error("Unable to parse Measurement Data \(data.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                    return nil
                }
                
                log.debug("Parsed measurement \(parsed.description).")
                return parsed
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [log] _ in
                log.debug("Completion")
            }, receiveValue: { [weak self] newValue in
                switch self?.request {
                case .first:
                    self?.firstRecord = newValue
                case .last:
                    self?.lastRecord = newValue
                default:
                    self?.allRecords.append(newValue)
                }
            })
            .store(in: &cancellables)
    }
}

// MARK: - CustomStringConvertible

extension GlucoseMeasurement: @retroactive CustomStringConvertible {
    
    public var description: String {
        return String(format: "%.2f \(measurement.unit.symbol), Seq.: \(sequenceNumber), Date: \(toStringDate()), Sensor: \(sensorString()), Location: \(locationString()), Status: \(statusString())", measurement.value)
    }
}

// MARK: - Error

extension GlucoseViewModel {
    
    enum CriticalError: LocalizedError {
        case cannotFindGlucoseMeasurementCCD
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let glucoseService = CBUUID(service: .glucose)
}
