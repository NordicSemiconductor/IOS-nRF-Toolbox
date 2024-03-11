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
        
        private let l = L(category: "DeviceDetails.VM")
         
        func viewModel<T>(ofType type: T.Type) -> T? {
            supportedServiceViewModels.firstOfType(type: type.self)
        }
    
        init (
            cbPeripheral: CBPeripheral,
            centralManager: CentralManager
        ) {
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
            
            l.construct()
        }
        
        deinit {
            l.descruct()
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
            self.environment.services = discoveredServices.map { Service(cbService: $0) }
           
            for service in discoveredServices {
                switch service.uuid {
                case .runningSpeedCadence:
                    supportedServiceViewModels.append(RunningServiceScreen.RunningServiceViewModel(peripheral: peripheral, runningService: service))
                case .heartRate:
                    supportedServiceViewModels.append(HeartRateScreen.HeartRateViewModel(peripheral: peripheral, hrService: service))
                case .healthThermometer:
                    supportedServiceViewModels.append(HealthThermometerScreen.VM(peripheral: peripheral, service: service))
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
        @Published fileprivate (set) var services: [Service]
        
        @Published var reconnecting: Bool
        @Published var criticalError: CriticalError?
        @Published var alertError: AlertError?
        
        @Published var peripheralName: String?
        @Published var showInspector: Bool = false 
        
        let deviceID: UUID
        
        fileprivate (set) var peripheralViewModel: PeripheralInspectorScreen.PeripheralInspectorViewModel?
        
        fileprivate (set) var reconnect: (() async -> ())?
        
        private let l = L(category: "DeviceDetails.Env")
        
        init(
            deviceID: UUID,
            services: [Service] = [],
            reconnecting: Bool = false,
            criticalError: CriticalError? = nil,
            alertError: AlertError? = nil,
            peripheralViewModel: PeripheralInspectorScreen.PeripheralInspectorViewModel? = nil, // PeripheralInspectorScreen.MockViewModel.shared,
            reconnect: (() async -> ())? = nil
        ) {
            self.deviceID = deviceID
            self.services = services
            self.reconnecting = reconnecting
            self.criticalError = criticalError
            self.alertError = alertError
            self.peripheralViewModel = peripheralViewModel
            self.reconnect = reconnect
            
            l.construct()
        }
        
        deinit {
            l.descruct()
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
