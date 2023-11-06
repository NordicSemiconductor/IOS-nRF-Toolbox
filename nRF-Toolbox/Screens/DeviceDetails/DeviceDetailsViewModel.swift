//
//  DeviceDetailsViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database

extension DeviceDetailsScreen {
    @MainActor
    class ViewModel: ObservableObject {
        private var discoveredServices: [CBService] = []
        
        let peripheral: Peripheral
        var id: UUID { peripheral.peripheral.identifier }
        
        let environment: Environment
        lazy private (set) var runningServiceViewModel: RunningServiceScreen.ViewModel? = {
            if let service = discoveredServices.first(where: { $0.uuid == Service.runningSpeedAndCadence.uuid }) {
                return RunningServiceScreen.ViewModel(peripheral: peripheral, runningService: service)
            } else {
                return nil
            }
        }()
        lazy private (set) var heartRateServiceViewModel: HeartRateScreen.ViewModel? = {
            if let service = discoveredServices.first(where: { $0.uuid == Service.heartRate.uuid }) {
                return HeartRateScreen.ViewModel(peripheral: peripheral, hrService: service)
            } else {
                return nil
            }
        }()
    
        lazy private (set) var signalChartViewModel = SignalChartScreen.ViewModel(peripheral: peripheral)
        
        init(cbPeripheral: CBPeripheral) {
            self.peripheral = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
            self.environment = Environment(peripheralViewModel: PeripheralScreen.ViewModel(peripheral: peripheral))
            self.environment.peripheralName = peripheral.name
            
            Task {
                await discoverSupportedServices()
            }
        }
    }
}

// MARK: - Service View Models
extension DeviceDetailsScreen.ViewModel {
    private func discoverSupportedServices() async {
        let supportedServices = Service.supportedServices.map { CBUUID(service: $0) }
        do {
            discoveredServices = try await peripheral.discoverServices(serviceUUIDs: supportedServices).value
            self.environment.services = discoveredServices.map { Service(cbService: $0) }
        } catch {
            environment.error = ReadableError(title: "Error", message: "Unnable to discover services")
        }
    }
}

extension DeviceDetailsScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var services: [Service]
        
        @Published var error: ReadableError?
        
        @Published var peripheralName: String?
        
        fileprivate (set) var peripheralViewModel: PeripheralScreen.ViewModel
        
        init(
            services: [Service] = [],
            error: ReadableError? = nil,
            peripheralViewModel: PeripheralScreen.ViewModel = PeripheralScreen.MockViewModel.shared
        ) {
            self.services = services
            self.error = error
            self.peripheralViewModel = peripheralViewModel
        }
    }
}
