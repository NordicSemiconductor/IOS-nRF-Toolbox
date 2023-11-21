//
//  DeviceDetailsViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

private extension Array {
    func firstOfType<T>(type: T.Type) -> T? {
        first(where: { $0 is T }).flatMap({ $0 as? T })
    }
}

protocol SupportedServiceViewModel {
    func onConnect()
    func onDisconnect()
}

extension DeviceDetailsScreen {
    @MainActor
    class DeviceDetailsViewModel {
        private var discoveredServices: [CBService] = []
        private var cancelable = Set<AnyCancellable>()
        
        let centralManager: CentralManager
        let peripheral: Peripheral
        
        var id: UUID { peripheral.peripheral.identifier }
        
        let environment: Environment
        private var supportedServiceViewModels: [SupportedServiceViewModel] = []
        
        private let l = L(subsystem: "com.nrf-toolbox", category: #function)
        
        var runningServiceViewModel: RunningServiceScreen.ViewModel? {
            supportedServiceViewModels.firstOfType(type: RunningServiceScreen.ViewModel.self)
        }
        
        var heartRateServiceViewModel: HeartRateScreen.HeartRateViewModel? {
            supportedServiceViewModels.firstOfType(type: HeartRateScreen.HeartRateViewModel.self)
        }
    
        init (
            cbPeripheral: CBPeripheral,
            centralManager: CentralManager
        ) {
            self.peripheral = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
            self.centralManager = centralManager
            self.environment = Environment(
                deviceID: peripheral.peripheral.identifier,
                peripheralViewModel: PeripheralInspectorScreen.ViewModel(peripheral: peripheral)
            )
            self.environment.peripheralName = peripheral.name
            
            l.i(#function)
            
            self.subscribeOnConnection()
            
            Task {
                await discoverSupportedServices()
            }
            
            self.environment.reconnect = {
                await self.reconnect()
            }
        }
        
        deinit {
            l.i("Deinit of View Model")
        }
    }
}

extension DeviceDetailsScreen.DeviceDetailsViewModel {
    private struct TimeoutError: Error { }
    
    func onDisconnect() {
        supportedServiceViewModels.forEach { $0.onDisconnect() }
        environment.peripheralViewModel.onDisconnect()
    }
    
    func reconnect() async {
        do {
            environment.reconnecting = true
            _ = try await centralManager.connect(peripheral.peripheral)
                .timeout(5, scheduler: DispatchQueue.main, customError: {
                    TimeoutError()
                })
                .value
            
            self.onDisconnect()
            environment.criticalError = nil
        } catch {
            
        }
        environment.reconnecting = false 
    }
}

// MARK: - Service View Models
extension DeviceDetailsScreen.DeviceDetailsViewModel {
    private func discoverSupportedServices() async {
        let supportedServices = Service.supportedServices.map { CBUUID(service: $0) }
        do {
            discoveredServices = try await peripheral.discoverServices(serviceUUIDs: supportedServices).value
            self.environment.services = discoveredServices.map { Service(cbService: $0) }
            
            for s in discoveredServices {
                l.d(s.uuid.uuidString)
            }
            
            if discoveredServices.isEmpty {
                l.d("No Service found")
            }
            
            for service in discoveredServices {
                switch service.uuid {
                case .runningSpeedCadence:
                    supportedServiceViewModels.append(RunningServiceScreen.ViewModel(peripheral: peripheral, runningService: service))
                case .heartRate:
                    supportedServiceViewModels.append(HeartRateScreen.HeartRateViewModel(peripheral: peripheral, hrService: service))
                default:
                    break
                }
            }
        } catch {
            environment.alertError = .servicesNotFount
        }
    }
    
    private func subscribeOnConnection() {
        centralManager.disconnectedPeripheralsChannel
            .filter { [unowned self] in $0.0.identifier == self.id }
            .compactMap { $0.1 }
            .sink { [unowned self] err in
                supportedServiceViewModels.forEach { $0.onDisconnect() }
                environment.peripheralViewModel.env.signalChartViewModel.onDisconnect()
                environment.criticalError = .disconnectedWithError(err)
            }
            .store(in: &cancelable)
    }
}

extension DeviceDetailsScreen.DeviceDetailsViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var services: [Service]
        
        @Published var reconnecting: Bool
        @Published var criticalError: CriticalError?
        @Published var alertError: AlertError?
        
        @Published var peripheralName: String?
        
        let deviceID: UUID
        
        fileprivate (set) var peripheralViewModel: PeripheralInspectorScreen.ViewModel
        
        fileprivate (set) var reconnect: (() async -> ())?
        
        private let l = L(subsystem: "com.nrf-toolbox", category: #function)
        
        init(
            deviceID: UUID,
            services: [Service] = [],
            reconnecting: Bool = false,
            criticalError: CriticalError? = nil,
            alertError: AlertError? = nil,
            peripheralViewModel: PeripheralInspectorScreen.ViewModel = PeripheralInspectorScreen.MockViewModel.shared,
            reconnect: (() async -> ())? = nil
        ) {
            self.deviceID = deviceID
            self.services = services
            self.reconnecting = reconnecting
            self.criticalError = criticalError
            self.alertError = alertError
            self.peripheralViewModel = peripheralViewModel
            self.reconnect = reconnect
        }
        
        deinit {
            l.i(#function)
        }
    }
    
}

extension DeviceDetailsScreen.DeviceDetailsViewModel {
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
