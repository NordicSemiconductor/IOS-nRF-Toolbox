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
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - CGMSViewModel

final class CGMSViewModel: SupportedServiceViewModel, ObservableObject {
    
    // MARK: Private Properties
    
    private let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    private var peripheralSessionTime: Date!
    private var cbCGMMeasurement: CBCharacteristic!
    private var cbSOCP: CBCharacteristic!
    private var cbRACP: CBCharacteristic!
    private var cbFeature: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "CGMSViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var sessionStarted = false
    @Published private(set) var firstRecord: CGMSMeasurement?
    @Published private(set) var records = [CGMSMeasurement]()
    @Published private(set) var lastRecord: CGMSMeasurement?
    @Published private(set) var inFlightRequest: RecordOperator?
    @Published private(set) var minY = 80.0
    @Published private(set) var maxY = 100.0
    @Published var scrollPosition = -1
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    // MARK: init
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.characteristics = characteristics
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
        
        $records.sink { records in
            let values = records.map { $0.measurement.value }

            let minY = (values.min() ?? 0) - 5.0
            let maxY = (values.max() ?? 0) + 5.0

            self.minY = minY
            self.maxY = maxY
        }.store(in: &cancellables)
    }
    
    // MARK: requestNumberOfRecords()
    
    @MainActor
    func requestNumberOfRecords() async throws -> Int {
        log.debug(#function)
        do {
            async let racpDataResponse = listenRACPResponse()
            
            let writeStoreCountData = Data([RecordOpcode.reportNumberOfRecords.rawValue, 1])
            log.debug("peripheral.writeValueWithResponse(\(writeStoreCountData.hexEncodedString(options: [.prepend0x, .upperCase])))")
            try await peripheral.writeValueWithResponse(writeStoreCountData, for: cbRACP).firstValue
            
            let racpData = try await racpDataResponse
            let offset = MemoryLayout<UInt16>.size
            let numberOfRecords: UInt8? = try? racpData.read(fromOffset: offset)
            log.debug("RACP response \(racpData.hexEncodedString(options: [.prepend0x, .upperCase]))")
            
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
    
    // MARK: listenRACPResponse()
    
    func listenRACPResponse() async throws -> Data {
        log.debug(#function)
        let racpData = try await peripheral.listenValues(for: cbRACP).firstValue
        log.debug("\(#function) Response \(racpData.hexEncodedString(options: [.prepend0x, .upperCase]))")
        
        return racpData
    }
    
    // MARK: requestRecords()
    
    @MainActor
    func requestRecords(_ op: RecordOperator) async {
        log.debug(#function)
        inFlightRequest = op
        defer {
            inFlightRequest = nil
        }
        
        do {
            records = []
            if let numberOfRecords = try? await requestNumberOfRecords() {
                log.debug("Number of records \(numberOfRecords)")
                records.reserveCapacity(numberOfRecords)
            }
            
            async let racpData = listenRACPResponse()
            
            let writeData = Data([RecordOpcode.reportStoredRecords.rawValue, op.rawValue])
            log.debug("peripheral.writeValueWithResponse(\(writeData.hexEncodedString(options: [.prepend0x, .upperCase])))")
            try await peripheral.writeValueWithResponse(writeData, for: cbRACP).firstValue
            
            log.debug("Received \(try await racpData)")
        } catch {
            log.debug(error.localizedDescription)
            handleError(error)
        }
    }
    
    // MARK: description
    
    var description: String {
        "Continuous Glucose Monitoring Service"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return CGMSView()
            .environmentObject(self)
    }
    
    // MARK: onConnect()
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        do {
            try await initializeCharacteristics()
        } catch {
            log.error("Error \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    @MainActor
    private func initializeCharacteristics() async throws {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .cgmMeasurement, .recordAccessControlPoint,
            .cgmSpecificOpsControlPoint, .cgmSessionStartTime, .cgmFeature
        ]
        let cbCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
            characteristics.contains { $0.uuid == cbChar.uuid }
        }
        
        self.cbCGMMeasurement = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.cgmMeasurement.uuid)
        self.cbRACP = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.recordAccessControlPoint.uuid)
        self.cbSOCP = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.cgmSpecificOpsControlPoint.uuid)
        self.cbFeature = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.cgmFeature.uuid)
        let cbSST = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.cgmSessionStartTime.uuid)
        
        guard let cbCGMMeasurement, let cbSOCP, let cbSST else {
            throw ServiceError.noMandatoryCharacteristic
        }
        
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
        
        let racpEnable = try await peripheral.setNotifyValue(true, for: cbRACP).firstValue
        log.debug("CGMS RACP.setNotifyValue(true): \(racpEnable)")
        
        var secured = false
        let featuresRaw = try? await peripheral.readValue(for: cbFeature).firstValue
        if let featuresRaw {
            log.debug("Received features data: \(featuresRaw.hexEncodedString(options: [.upperCase, .twoByteSpacing])))")
            let result = CGMSFeatureParser.parse(data: featuresRaw)
            secured = result?.secured ?? false
        }
        
        // Starts session. Since now records are generated.
        let startSessionData = createStartSession(opCode: CGMOpCode.startSession.rawValue, secure: secured)
        try await peripheral.writeValueWithResponse(startSessionData, for: cbSOCP).firstValue
        
        await requestRecords(.allRecords)
    }
    
    private func createStartSession(opCode: UInt8, secure: Bool) -> Data {
        var data = Data(capacity: 1 + (secure ? 2 : 0))
        data.append(opCode)
        
        if secure {
            var crc = CRC16.mcrf4xx(data: data, offset: 0, length: data.count)
            data.append(contentsOf: Data(bytes: &crc, count: MemoryLayout<UInt16>.size))
        }
        
        return data
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        peripheralSessionTime = nil
        cbCGMMeasurement = nil
        cbSOCP = nil
        cbRACP = nil
        cancellables.removeAll()
    }
}

// MARK: - Private

private extension CGMSViewModel {
    
    // MARK: listenToMeasurements()
    
    func listenToMeasurements(_ measurementCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: measurementCharacteristic)
            .compactMap { [log, peripheralSessionTime] data -> [CGMSMeasurement] in
                log.debug("Received Measurement Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) (\(data.count) bytes)")
                
                guard let peripheralSessionTime else { return [] }
                
                return CGMSMeasurementParser.parse(data: data, sessionStartTime: peripheralSessionTime)
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                print("Completion")
            }, receiveValue: { [weak self] newValues in
                guard let self, !newValues.isEmpty else { return }
                switch self.inFlightRequest {
                case .firstRecord:
                    self.firstRecord = newValues.first!
                case .lastRecord:
                    self.lastRecord = newValues.first!
                default: // also .allRecords
                    self.records += newValues
                    if scrollPosition >= self.records.endIndex-10 {
                        scrollPosition = max(0, self.records.endIndex-5)
                    }
                }
                
            })
            .store(in: &cancellables)
    }
    
    func listenToOperations(_ opsControlPointCharacteristic: CBCharacteristic) {
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
}

// MARK: - CBUUID

extension CBUUID {
    
    static let continuousGlucoseMonitoringService = CBUUID(service: .continuousGlucoseMonitoring)
}
