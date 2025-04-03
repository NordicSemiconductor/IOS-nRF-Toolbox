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
    private var cbSOCPMeasurement: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "CGMSViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var sessionStarted = false
    @Published private(set) var records = [CGMSMeasurement]()
    
    // MARK: init
    
    init(peripheral: Peripheral, cgmsService: CBService) {
        self.peripheral = peripheral
        self.service = cgmsService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

extension CGMSViewModel {
    
    func toggleSession() {
        Task { @MainActor in
            sessionStarted.toggle()
            do {
                let writeData: Data
                switch sessionStarted {
                case true:
                    writeData = Data([CGMOpCode.startSession.rawValue])
                case false:
                    writeData = Data([CGMOpCode.stopStopSession.rawValue])
                }
                log.debug("peripheral.writeValueWithResponse(\(writeData.hexEncodedString(options: [.prepend0x, .upperCase])))")
                try await peripheral.writeValueWithResponse(writeData, for: cbSOCPMeasurement).firstValue
            } catch {
                sessionStarted = false
                log.debug(error.localizedDescription)
            }
        }
    }
}

// MARK: - SupportedServiceViewModel

extension CGMSViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .cgmMeasurement, .recordAccessControlPoint,
            .cgmSpecificOpsControlPoint, .cgmStatus, .cgmFeature
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        cbSOCPMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmSpecificOpsControlPoint.uuid)
        
        guard let cbCgmMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.cgmMeasurement.uuid),
              let cbRacpMeasurement = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.recordAccessControlPoint.uuid),
              let cbSOCPMeasurement else {
            return
        }
        
        do {
            listenTo(cbCgmMeasurement)
            let cgmEnable = try await peripheral.setNotifyValue(true, for: cbCgmMeasurement).firstValue
            log.debug("CGMS Measurement.setNotifyValue(true): \(cgmEnable)")
            
//            guard result else {
//                // TODO: throw Error
//            }
            let socpEnable = try await peripheral.setNotifyValue(true, for: cbSOCPMeasurement).firstValue
            log.debug("CGMS SOCP.setNotifyValue(true): \(socpEnable)")
            
            let racpEnable = try await peripheral.setNotifyValue(true, for: cbRacpMeasurement).firstValue
            log.debug("CGMS RACP.setNotifyValue(true): \(racpEnable)")
        } catch {
            log.error(error.localizedDescription)
            onDisconnect()
        }
    }
    
    private func listenTo(_ measurementCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: measurementCharacteristic)
            .receive(on: RunLoop.main)
            .compactMap { [log] data in
                guard let parse = try? CGMSMeasurement(data: data, sessionStartTime: .now) else {
                    log.error("Unable to parse Measurement Data \(data.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                    return nil
                }
                log.debug("Parsed measurement \(parse). Seq. No.: \(parse.sequenceNumber)")
                return parse
            }
            .sink(receiveCompletion: { _ in
                print("Completion")
            }, receiveValue: { newValue in
                self.records.append(newValue)
            })
            .store(in: &cancellables)
    }
    
    func onDisconnect() {
        log.debug(#function)
        cbSOCPMeasurement = nil
        cancellables.removeAll()
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let continuousGlucoseMonitoringService = CBUUID(service: .continuousGlucoseMonitoring)
}
