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
            self.environment = Environment(peripheralViewModel: PeripheralInspectorScreen.ViewModel(peripheral: peripheral))
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
            environment.alertError = .servicesNotFount
        }
    }
}

extension DeviceDetailsScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var services: [Service]
        
        @Published var criticalError: CriticalError?
        @Published var alertError: AlertError?
        
        @Published var peripheralName: String?
        
        fileprivate (set) var peripheralViewModel: PeripheralInspectorScreen.ViewModel
        
        init(
            services: [Service] = [],
            criticalError: CriticalError? = nil,
            alertError: AlertError? = nil,
            peripheralViewModel: PeripheralInspectorScreen.ViewModel = PeripheralInspectorScreen.MockViewModel.shared
        ) {
            self.services = services
            self.criticalError = criticalError
            self.alertError = alertError
            self.peripheralViewModel = peripheralViewModel
        }
    }
}

extension DeviceDetailsScreen.ViewModel {
    enum CriticalError: Error {
        case disconnectedWithError(Error?)

        var title: String {
            switch self {
            case .disconnectedWithError:
                return "Disconnected"
            }
        }

        var message: String {
            switch self {
            case .disconnectedWithError(let error):
                return error?.localizedDescription ?? "Disconnected with unknown error."
            }
        }
    }

    enum AlertError: Error {
        case servicesNotFount

        var title: String {
            switch self {
            case .servicesNotFount:
                return "Services not found"
            }
        }

        var message: String {
            switch self {
            case .servicesNotFount:
                return "Error occured while discovering services."
            }
        }
    }
}
