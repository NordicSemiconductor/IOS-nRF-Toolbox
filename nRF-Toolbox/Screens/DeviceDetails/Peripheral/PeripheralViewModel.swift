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
import CoreBluetoothMock_Collection

private typealias ViewModel = PeripheralScreen.ViewModel

extension PeripheralScreen {
    @MainActor 
    class ViewModel: ObservableObject {
        let env: Environment
        private static let batteryLevelDataLength = 120

        private var cancellables = Set<AnyCancellable>()
        
        private let peripheral: Peripheral
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
            
            self.env = Environment(
                signalChartViewModel: SignalChartScreen.ViewModel(peripheral: peripheral),
                attributeTableViewModel: AttributeTableScreen.ViewModel(peripheral: peripheral)
            )
            
            env.signalChartViewModel.readSignal()
            
            setupBattery()
        }
        
        func setupBattery() {
            Task {
                try? await discoverServices()
            }
        }
    }
    
    #if DEBUG
    @MainActor
    class MockViewModel: ViewModel {
        static let shared = MockViewModel(peripheral: .preview)
    }
    #endif
}

// MARK: Private Methods
private extension ViewModel {
    
    private func discoverServices() async throws {
        // Discover Services
        let services: [Service] = [.batteryService]
        let cbServices = try await peripheral
            .discoverServices(serviceUUIDs: services.map(\.uuid))
            .timeout(1, scheduler: DispatchQueue.main)
            .value
        
        // Check if battery service was discovered
        guard let cbBatteryLevel = cbServices.first,
                cbBatteryLevel.uuid == Service.batteryService.uuid else {
            return
        }
        
        // Discover Characteristics
        let characteristics: [Characteristic] = [.batteryLevel]
        let cbCharacteristics = try await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: cbBatteryLevel)
            .timeout(1, scheduler: DispatchQueue.main)
            .value
        
        // Check if `batteryLevel` characteristic was discovered
        guard let cbBatteryLevel = cbCharacteristics.first, cbBatteryLevel.uuid == Characteristic.batteryLevel.uuid else {
            return
        }
        
        env.batteryLevelAvailable = true
        
        do {
            // try to enable notifications for
            if try await peripheral.setNotifyValue(true, for: cbBatteryLevel).timeout(1, scheduler: DispatchQueue.main).value {
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
extension PeripheralScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var criticalError: CriticalError?
        @Published var alertError: Error?
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
        
        @Published fileprivate (set) var batteryLevelData: [ChartTimeData<Battery.Level>]
        @Published fileprivate (set) var currentBatteryLevel: UInt? = nil
        @Published fileprivate (set) var batteryLevelAvailable: Bool = false
        
        let signalChartViewModel: SignalChartScreen.ViewModel
        let attributeTableViewModel: AttributeTableScreen.ViewModel
        
        fileprivate (set) var disconnect: () -> ()
        
        init(
            criticalError: CriticalError? = nil,
            alertError: Error? = nil,
            internalAlertError: AlertError? = nil,
            batteryLevelData: [ChartTimeData<Battery.Level>] = [],
            currentBatteryLevel: UInt? = nil,
            batteryLevelAvailable: Bool = false,
            signalChartViewModel: SignalChartScreen.ViewModel = SignalChartScreen.MockViewModel.shared,
            attributeTableViewModel: AttributeTableScreen.ViewModel = AttributeTableScreen.MockViewModel.shared,
            disconnect: @escaping () -> () = { }
        ) {
            self.criticalError = criticalError
            self.alertError = alertError
            self.internalAlertError = internalAlertError
            self.batteryLevelData = batteryLevelData
            self.currentBatteryLevel = currentBatteryLevel
            self.batteryLevelAvailable = batteryLevelAvailable
            self.signalChartViewModel = signalChartViewModel
            self.attributeTableViewModel = attributeTableViewModel
            self.disconnect = disconnect
        }
    }
}

// MARK: - Errors
extension PeripheralScreen.ViewModel.Environment {
    enum CriticalError: LocalizedError {
        case unknown
    }

    enum AlertError: LocalizedError {
        case unknown
    }
}

extension PeripheralScreen.ViewModel.Environment.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}

extension PeripheralScreen.ViewModel.Environment.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}
