//
//  CGMSViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 1/4/25.
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

// MARK: - CGMSViewModel

final class CGMSViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var peripheralSessionTime: Date!
    private var cbCGMMeasurement: CBCharacteristic!
    private var cbSOCP: CBCharacteristic!
    private var cbRACP: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "CGMSViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var sessionStarted = false
    @Published private(set) var records = [CGMSMeasurement]()
    @Published var scrollPosition = 0
    
    // MARK: init
    
    init(peripheral: Peripheral, cgmsService: CBService) {
        self.peripheral = peripheral
        self.service = cgmsService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

extension CGMSViewModel {
    
    @MainActor
    func requestNumberOfRecords() async throws -> Int {
        log.debug(#function)
        do {
            let racpEnable = try await peripheral.setNotifyValue(true, for: cbRACP).firstValue
            log.debug("\(#function) RACP.setNotifyValue(true): \(racpEnable)")
            
            let writeStoreCountData = Data([RACPOpCode.reportStoredRecordsCount.rawValue, 1])
            log.debug("peripheral.writeValueWithResponse(\(writeStoreCountData.hexEncodedString(options: [.prepend0x, .upperCase])))")
            try await peripheral.writeValueWithResponse(writeStoreCountData, for: cbRACP).firstValue
            
            let racpData = try await peripheral.listenValues(for: cbRACP).firstValue
            let offset = MemoryLayout<UInt16>.size
            let numberOfRecords: UInt8? = try? racpData.read(fromOffset: offset)
            log.debug("Response \(racpData.hexEncodedString(options: [.prepend0x, .upperCase]))")
            
            let racpDisable = try await peripheral.setNotifyValue(false, for: cbRACP).firstValue
            log.debug("\(#function) RACP.setNotifyValue(false): \(racpDisable)")
            
            if let numberOfRecords {
                log.debug("Number of Records: \(numberOfRecords)")
                return Int(numberOfRecords)
            }
        } catch {
            log.debug(error.localizedDescription)
            let _ = try await peripheral.setNotifyValue(false, for: cbRACP).firstValue
            throw error
        }
        
        throw ReadableError(title: #function, message: "Unable to Read Number of Records")
    }
    
    @MainActor
    func requestAllRecords() async {
        log.debug(#function)
        do {
            records = []
            if let numberOfRecords = try? await requestNumberOfRecords() {
                records.reserveCapacity(numberOfRecords)
            }
            
            let writeData = Data([RACPOpCode.reportStoredRecords.rawValue, 1])
            log.debug("peripheral.writeValueWithResponse(\(writeData.hexEncodedString(options: [.prepend0x, .upperCase])))")
            try await peripheral.writeValueWithResponse(writeData, for: cbRACP).firstValue
        } catch {
            log.debug(error.localizedDescription)
        }
    }
}

// MARK: - RACPOpCode

enum RACPOpCode: UInt8 {
    case reserved = 0
    case reportStoredRecords = 1
    case deleteStoredRecords = 2
    case abort = 3
    case reportStoredRecordsCount = 4
    case numberOfStoredRecords = 5
    case response = 6
}

// MARK: - SupportedServiceViewModel

extension CGMSViewModel: SupportedServiceViewModel {
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .cgmMeasurement, .recordAccessControlPoint,
            .cgmSpecificOpsControlPoint, .cgmSessionStartTime
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        cbCGMMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmMeasurement.uuid)
        cbRACP = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.recordAccessControlPoint.uuid)
        cbSOCP = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmSpecificOpsControlPoint.uuid)
        let cbSST = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmSessionStartTime.uuid)
        
        guard let cbCGMMeasurement, let cbSOCP, let cbSST else {
            return
        }
        
        do {
            let now = Date.now
            if let dateData = now.toData(options: [.appendTimeZone, .appendDSTOffset]) {
                log.debug("Sending SST (Session Start Time): \(dateData.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                try await peripheral.writeValueWithResponse(dateData, for: cbSST).firstValue
            }
            
            if let sstData = try await peripheral.readValue(for: cbSST).firstValue {
                log.debug("SST: \(sstData.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                peripheralSessionTime = Date(sstData)
            } else {
                log.debug("Unable to read SST. Defaulting to now.")
                peripheralSessionTime = .now
            }
            
            listenToMeasurements(cbCGMMeasurement)
            let cgmEnable = try await peripheral.setNotifyValue(true, for: cbCGMMeasurement).firstValue
            log.debug("CGMS Measurement.setNotifyValue(true): \(cgmEnable)")
            
//            guard result else {
//                // TODO: throw Error
//            }
            
            listenToOperations(cbSOCP)
            let socpEnable = try await peripheral.setNotifyValue(true, for: cbSOCP).firstValue
            log.debug("CGMS SOCP.setNotifyValue(true): \(socpEnable)")
            
            await requestAllRecords()
        } catch {
            log.error(error.localizedDescription)
            onDisconnect()
        }
    }
    
    private func listenToMeasurements(_ measurementCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: measurementCharacteristic)
            .compactMap { [log, peripheralSessionTime] data -> CGMSMeasurement? in
                log.debug("Received Measurement Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) (\(data.count) bytes)")
                guard let peripheralSessionTime,
                      let parse = try? CGMSMeasurement(data: data, sessionStartTime: peripheralSessionTime) else {
                    log.error("Unable to parse Measurement Data \(data.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                    return nil
                }
                log.debug("Parsed measurement \(parse). Seq. No.: \(parse.sequenceNumber)")
                return parse
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                print("Completion")
            }, receiveValue: { newValue in
                self.records.append(newValue)
                self.scrollPosition = newValue.sequenceNumber
            })
            .store(in: &cancellables)
    }
    
    private func listenToOperations(_ opsControlPointCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: opsControlPointCharacteristic)
            .map { [log] data in
                log.debug("Received Ops Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing]))")
                return data
            }
            .sink(receiveCompletion: { _ in
                print("Completion")
            }, receiveValue: { [log] newValue in
                log.debug("Received new Ops Control Point Values")
            })
            .store(in: &cancellables)
    }
    
    func onDisconnect() {
        log.debug(#function)
        peripheralSessionTime = nil
        cbCGMMeasurement = nil
        cbSOCP = nil
        cbRACP = nil
        cancellables.removeAll()
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let continuousGlucoseMonitoringService = CBUUID(service: .continuousGlucoseMonitoring)
}
