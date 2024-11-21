//
//  PeripheralViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 30/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

private typealias ViewModel = PeripheralInspectorScreen.PeripheralInspectorViewModel

extension PeripheralInspectorScreen {
    
    @MainActor
    class PeripheralInspectorViewModel {
        let env: Environment
        private static let batteryLevelDataLength = 120

        private var cancellables = Set<AnyCancellable>()
        
        private let peripheral: Peripheral
        
        private let l = NordicLog(category: "PeripheralInspector.VM")
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
            self.env = Environment(
                deviceId: peripheral.peripheral.identifier,
                signalChartViewModel: SignalChartScreen.SignalChartViewModel(peripheral: peripheral),
                attributeTableViewModel: AttributeTableScreen.AttributeTableViewModel(peripheral: peripheral)
            )
            onConnect()
            
            l.debug(#function)
        }
        
        deinit {
            l.debug(#function)
        }
        
        func onConnect() {
            env.signalChartViewModel.onConnect()
            
            Task {
                try? await discoverServices()
            }
        }
        
        func onDisconnect() {
            cancellables.removeAll()
            env.signalChartViewModel.onDisconnect()
        }
    }
    
    #if DEBUG
    @MainActor
    class MockViewModel: PeripheralInspectorViewModel {
        static let shared = MockViewModel(peripheral: .preview)
    }
    #endif
}

// MARK: Private Methods
private extension ViewModel {
    
    private func discoverServices() async throws {
        // Discover Services
        let services: [Service] = [.batteryService, .deviceInformation]
        let cbServices = try await peripheral
            .discoverServices(serviceUUIDs: services.map(\.uuid))
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        // Check if battery service was discovered
        if let cbBatteryLevel = cbServices.first(where: { $0.uuid == Service.batteryService.uuid }) {
            try await handleBatteryService(cbBatteryLevel, peripheral: peripheral)
        }
        
        if let cbDeviceInfo = cbServices.first(where: { $0.uuid == Service.deviceInformation.uuid }) {
            try await handleDeviceInformation(cbDeviceInfo, peripheral: peripheral)
        }
    }
    
    private func handleBatteryService(_ cbBatteryLevel: CBService, peripheral: Peripheral) async throws {
        let characteristics: [Characteristic] = [.batteryLevel]
        let cbCharacteristics = try await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: cbBatteryLevel)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        // Check if `batteryLevel` characteristic was discovered
        guard let cbBatteryLevel = cbCharacteristics.first, cbBatteryLevel.uuid == Characteristic.batteryLevel.uuid else {
            return
        }
        
        env.batteryLevelAvailable = true
        
        do {
            // try to enable notifications for
            if try await peripheral.setNotifyValue(true, for: cbBatteryLevel).timeout(1, scheduler: DispatchQueue.main).firstValue {
                // in case of success - listen
                listen(for: cbBatteryLevel)
            } else {
                // otherwise - read
                try? await readBatteryLevelOnTimer(cbBatteryLevel)
            }
        } catch {
            try? await readBatteryLevelOnTimer(cbBatteryLevel)
        }
    }
    
    private func handleDeviceInformation(_ cbDeviceInfo: CBService, peripheral: Peripheral) async throws {
        let deviceInfo = try await readDeviceInformation(from: cbDeviceInfo, peripheral: peripheral)
        
        env.deviceInfoAvailable = true
        env.deviceInfo = deviceInfo
    }
    
    private func readDeviceInformation(from service: CBService, peripheral: Peripheral) async throws -> DeviceInformation {
        let characteristics = try await peripheral.discoverCharacteristics(nil, for: service).firstValue

        var di = DeviceInformation()
        
        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.manufacturerNameString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.manufacturerName = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.modelNumberString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.modelNumber = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.serialNumberString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.serialNumber = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.hardwareRevisionString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.hardwareRevision = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.firmwareRevisionString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.firmwareRevision = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.softwareRevisionString.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.softwareRevision = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.systemId.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.systemID = String(data: data, encoding: .utf8)
            }
        }

        if let c = characteristics.first(where: { $0.uuid == CBUUID(string: Characteristic.ieee11073_20601RegulatoryCertificationDataList.uuidString) }) {
            if let data = try await peripheral.readValue(for: c).firstValue {
                di.ieee11073 = String(data: data, encoding: .utf8)
            }
        }
        
        return di
    }

    
    private func readBatteryLevelOnTimer(_ batteryLevelCh: CBCharacteristic, timeInterval: TimeInterval = 1) async throws {
        let publisher = Timer.publish(every: 60, on: .main, in: .default)
            .autoconnect()
            .flatMap { [unowned self] _ in self.peripheral.readValue(for: batteryLevelCh) }
            .compactMap { $0 }
            .eraseToAnyPublisher()

        handleBatteryPublisher(publisher)
    }
    
    private func listen(for batteryLevelCh: CBCharacteristic) {
        let publisher = peripheral.listenValues(for: batteryLevelCh)
            .eraseToAnyPublisher()
        
        handleBatteryPublisher(publisher)
    }
    
    private func handleBatteryPublisher(_ publisher: AnyPublisher<Data, Error>) {
        publisher
            .map { Battery.Level(data: $0) }
            .map { ChartTimeData<Battery.Level>(value: $0) }
            .scan(Array<ChartTimeData<Battery.Level>>(), { result, lvl in
                var res = result
                res.append(lvl)
                if res.count > Self.batteryLevelDataLength {
                    res.removeFirst()
                }
                return res
            })
            .sink { completion in
                
            } receiveValue: { [unowned self] level in
                var lvlData = level
                while lvlData.count < Self.batteryLevelDataLength {
                    let date = (lvlData.last?.date).map { Date(timeInterval: 1, since: $0) } ?? Date()
                    lvlData.append(.init(value: 0, date: date))
                }
                
                self.env.batteryLevelData = lvlData
            }
            .store(in: &cancellables)
    }
}

private extension ViewModel {
    enum Err: Error {
        case unknown
    }
}

// MARK: - Environment
extension PeripheralInspectorScreen.PeripheralInspectorViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate(set) var criticalError: CriticalError?
        @Published var alertError: Error?
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
        
        @Published fileprivate(set) var batteryLevelData: [ChartTimeData<Battery.Level>]
        @Published fileprivate(set) var currentBatteryLevel: UInt? = nil
        @Published fileprivate(set) var batteryLevelAvailable: Bool = false
        @Published fileprivate(set) var deviceInfoAvailable: Bool = false
        @Published fileprivate(set) var deviceInfo: DeviceInformation = DeviceInformation()
        
        let deviceId: UUID
        
        let signalChartViewModel: SignalChartScreen.SignalChartViewModel
        let attributeTableViewModel: AttributeTableScreen.AttributeTableViewModel
        
        fileprivate(set) var disconnect: () -> ()
        
        private let l = NordicLog(category: "PeripheralInspector.Env")
        
        init(
            deviceId: UUID,
            criticalError: CriticalError? = nil,
            alertError: Error? = nil,
            internalAlertError: AlertError? = nil,
            batteryLevelData: [ChartTimeData<Battery.Level>] = [],
            currentBatteryLevel: UInt? = nil,
            batteryLevelAvailable: Bool = false,
            deviceInfoAvailable: Bool = false,
            deviceInfo: DeviceInformation = DeviceInformation(),
            signalChartViewModel: SignalChartScreen.SignalChartViewModel = SignalChartScreen.MockViewModel.shared,
            attributeTableViewModel: AttributeTableScreen.AttributeTableViewModel = AttributeTableScreen.MockViewModel.shared,
            disconnect: @escaping () -> () = { }
        ) {
            self.deviceId = deviceId
            self.criticalError = criticalError
            self.alertError = alertError
            self.internalAlertError = internalAlertError
            self.batteryLevelData = batteryLevelData
            self.currentBatteryLevel = currentBatteryLevel
            self.batteryLevelAvailable = batteryLevelAvailable
            self.deviceInfoAvailable = deviceInfoAvailable
            self.deviceInfo = deviceInfo
            self.signalChartViewModel = signalChartViewModel
            self.attributeTableViewModel = attributeTableViewModel
            self.disconnect = disconnect
            
            l.debug(#function)
        }
        
        deinit {
            l.debug(#function)
        }
    }
}

// MARK: - Errors
extension PeripheralInspectorScreen.PeripheralInspectorViewModel.Environment {
    enum CriticalError: LocalizedError {
        case unknown
    }

    enum AlertError: LocalizedError {
        case unknown
    }
}

extension PeripheralInspectorScreen.PeripheralInspectorViewModel.Environment.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}

extension PeripheralInspectorScreen.PeripheralInspectorViewModel.Environment.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}
