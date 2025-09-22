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
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - GlucoseViewModel

@MainActor
final class GlucoseViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cbGlucoseMeasurement: CBCharacteristic!
    private var cbRACP: CBCharacteristic!
    private var glucoseNotifyEnabled: Bool = false
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "GlucoseViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var allRecords = [GlucoseMeasurement]()
    @Published private(set) var firstRecord: GlucoseMeasurement?
    @Published private(set) var lastRecord: GlucoseMeasurement?
    @Published private(set) var inFlightRequest: RecordOperator?
    @Published private(set) var minY = 0.6
    @Published private(set) var maxY = 0.0
    
    // MARK: init
    
    init(peripheral: Peripheral, glucoseService: CBService) {
        self.peripheral = peripheral
        self.service = glucoseService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
        
        $allRecords.sink { records in
            let values = records.map { $0.measurement.value }

            let minY = (values.min() ?? 0.2) - 0.2
            let maxY = (values.max() ?? 0.2) + 0.2

            self.minY = minY
            self.maxY = maxY
        }.store(in: &cancellables)
    }
}

// MARK: - SupportedServiceViewModel

extension GlucoseViewModel: @MainActor SupportedServiceViewModel {
    
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
            try await enableNotificationsIfNeeded()
            
            requestRecords(.allRecords)
        } catch {
            log.error(error.localizedDescription)
            onDisconnect()
        }
    }
    
    fileprivate func enableNotificationsIfNeeded() async throws {
        do {
            glucoseNotifyEnabled = try await peripheral.setNotifyValue(true, for: cbGlucoseMeasurement)
                .timeout(1, scheduler: RunLoop.main)
                .receive(on: RunLoop.main)
                .firstValue
            log.debug("GlucoseMeasurement.setNotifyValue(true): \(glucoseNotifyEnabled)")
            
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
    func requestRecords(_ op: RecordOperator) {
        Task { @MainActor in
            guard let cbRACP else { return }
            
            log.debug(#function)
            inFlightRequest = op
            defer {
                inFlightRequest = nil
            }
            do {
                try await enableNotificationsIfNeeded()
                
                if op == .allRecords {
                    allRecords.removeAll()
                }
                
                // If we don't listen to RACP and GLS Measurements, our firmware
                // will restart, fail, crash, or complain. Don't ask.
                let turnOnIndications = try await peripheral.setNotifyValue(true, for: cbRACP).firstValue
                log.debug("peripheral.setIndicate(true): \(turnOnIndications)")
                
                log.debug("peripheral.listenToRACPRequest()")
                async let racpResult = try peripheral.listenValues(for: cbRACP).firstValue
                
                let writeData = Data([RecordOpcode.reportStoredRecords.rawValue, op.rawValue])
                log.debug("peripheral.writeValueWithResponse(\(writeData.hexEncodedString(options: [.prepend0x, .upperCase])))")
                try await peripheral.writeValueWithResponse(writeData, for: cbRACP).firstValue
                
                let resultData = try await racpResult
                guard resultData.canRead(UInt8.self, atOffset: 0) else {
                    throw CriticalError.cannotFindGlucoseMeasurementCCD
                }
                log.debug("RACP Request Result: \(resultData)")
                try processRACPResponse(resultData)
                
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
                guard let self else { return }
                switch self.inFlightRequest {
                case .firstRecord:
                    self.firstRecord = newValue
                case .lastRecord:
                    self.lastRecord = newValue
                default:
                    self.allRecords.append(newValue)
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: processRACPResponse(:)
    
    @MainActor
    private func processRACPResponse(_ responseData: Data) throws {
        log.debug(#function)
        let opcodeValue = responseData.littleEndianBytes(atOffset: 0, as: UInt8.self)
        let recordOpcode = RecordOpcode(rawValue: UInt8(opcodeValue))
        switch recordOpcode {
        case .responseCode:
            guard responseData.count >= 4 * MemoryLayout<UInt8>.size else {
                throw CriticalError.invalidRACPResponseCode
            }
            
            let targetOpcodeValue = responseData.littleEndianBytes(atOffset: 2, as: UInt8.self)
            let statusCode = responseData.littleEndianBytes(atOffset: 3, as: UInt8.self)
            guard let targetOpcode = RecordOpcode(rawValue: UInt8(targetOpcodeValue)) else { break }
            let status = RecordResponseStatus(rawValue: UInt8(statusCode))
            log.debug("Response Code for \(targetOpcode.description): \(status?.description ?? "Reserved for Future Use")")
        default:
            break
        }
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
        case invalidRACPResponseCode
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let glucoseService = CBUUID(service: .glucose)
}
