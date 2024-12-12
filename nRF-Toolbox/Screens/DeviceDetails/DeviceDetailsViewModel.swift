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

// MARK: - SupportedServiceViewModel

protocol SupportedServiceViewModel {
    
    func onConnect() async
    func onDisconnect()
}

// MARK: - DeviceDetailsViewModel

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
        
        private let log = NordicLog(category: "DeviceDetails.VM", subsystem: "com.nordicsemi.nrf-toolbox")
        
        var runningServiceViewModel: RunningServiceViewModel? {
            supportedServiceViewModels.firstOfType(type: RunningServiceViewModel.self)
        }
        
        var cyclingServiceViewModel: CyclingServiceViewModel? {
            supportedServiceViewModels.firstOfType(type: CyclingServiceViewModel.self)
        }
        
        var heartRateServiceViewModel: DeviceScreen.HeartRateViewModel? {
            supportedServiceViewModels.firstOfType(type: DeviceScreen.HeartRateViewModel.self)
        }
        
        var temperatureServiceViewModel: TemperatureViewModel? {
            supportedServiceViewModels.firstOfType(type: TemperatureViewModel.self)
        }
        
        var batteryServiceViewModel: BatteryViewModel? {
            supportedServiceViewModels.firstOfType(type: BatteryViewModel.self)
        }
    
        init(cbPeripheral: CBPeripheral, centralManager: CentralManager) {
            self.peripheral = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
            self.centralManager = centralManager
            self.environment = Environment(
                deviceID: peripheral.peripheral.identifier,
                peripheralViewModel: PeripheralInspectorScreen.PeripheralInspectorViewModel(peripheral: peripheral)
            )
            
            self.environment.peripheralName = peripheral.name
            self.subscribeOnConnection()
            
            Task {
                await discoverSupportedServices()
            }
            
            self.environment.reconnect = { [weak self] in
                await self?.reconnect()
            }
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}

extension DeviceDetailsScreen.DeviceDetailsViewModel {
    private struct TimeoutError: Error { }
    
    func onDisconnect() {
        supportedServiceViewModels.forEach { $0.onDisconnect() }
        environment.peripheralViewModel?.onDisconnect()
    }
    
    func reconnect() async {
        do {
            environment.reconnecting = true
            _ = try await centralManager.connect(peripheral.peripheral)
                // Set timeout for 5 seconds
                .timeout(5, scheduler: DispatchQueue.main, customError: {
                    TimeoutError()
                })
                .firstValue
            
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
            discoveredServices = try await peripheral.discoverServices(serviceUUIDs: supportedServices).firstValue
            environment.services = discoveredServices.map { Service(cbService: $0) }
           
            for service in discoveredServices {
                switch service.uuid {
                case .runningSpeedCadence:
                    supportedServiceViewModels.append(RunningServiceViewModel(peripheral: peripheral, runningService: service))
                case .cyclingSpeedCadence:
                    supportedServiceViewModels.append(CyclingServiceViewModel(peripheral: peripheral, cyclingService: service))
                case .temperature:
                    supportedServiceViewModels.append(TemperatureViewModel(peripheral: peripheral, temperatureService: service))
                case .heartRate:
                    supportedServiceViewModels.append(DeviceScreen.HeartRateViewModel(peripheral: peripheral, heartRateService: service))
                case .battery:
                    supportedServiceViewModels.append(BatteryViewModel(peripheral: peripheral, batteryService: service))
                default:
                    break
                }
            }
            
            for supportedServiceViewModel in self.supportedServiceViewModels {
                await supportedServiceViewModel.onConnect()
            }
        } catch {
            environment.alertError = .servicesNotFound
        }
    }
    
    private func subscribeOnConnection() {
        centralManager.disconnectedPeripheralsChannel
            .filter { [unowned self] in $0.0.identifier == self.id }    // Filter other peripherals
            .compactMap { $0.1 }                                        // Handle only disconnections with error
            .sink { [unowned self] err in
                supportedServiceViewModels.forEach { $0.onDisconnect() }
                environment.peripheralViewModel?.env.signalChartViewModel.onDisconnect()
                // Display error
                environment.criticalError = .disconnectedWithError(err)
            }
            .store(in: &cancelable)
    }
}

extension DeviceDetailsScreen.DeviceDetailsViewModel {
    
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate(set) var services: [Service]
        
        @Published var reconnecting: Bool
        @Published var criticalError: CriticalError?
        @Published var alertError: AlertError?
        
        @Published var peripheralName: String?
        @Published var showInspector: Bool = false 
        
        let deviceID: UUID
        
        fileprivate(set) var peripheralViewModel: PeripheralInspectorScreen.PeripheralInspectorViewModel?
        
        fileprivate(set) var reconnect: (() async -> ())?
        
        private let log = NordicLog(category: "DeviceDetails.Env", subsystem: "com.nordicsemi.nrf-toolbox")
        
        init(deviceID: UUID, services: [Service] = [], reconnecting: Bool = false,
             criticalError: CriticalError? = nil,
             alertError: AlertError? = nil,
             peripheralViewModel: PeripheralInspectorScreen.PeripheralInspectorViewModel? = nil, // PeripheralInspectorScreen.MockViewModel.shared,
             reconnect: (() async -> ())? = nil) {
            self.deviceID = deviceID
            self.services = services
            self.reconnecting = reconnecting
            self.criticalError = criticalError
            self.alertError = alertError
            self.peripheralViewModel = peripheralViewModel
            self.reconnect = reconnect
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
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
        case servicesNotFound

        var title: String {
            switch self {
            case .servicesNotFound:
                return "Services not found"
            }
        }

        var message: String {
            switch self {
            case .servicesNotFound:
                return "Error occured while discovering services."
            }
        }
    }
}
