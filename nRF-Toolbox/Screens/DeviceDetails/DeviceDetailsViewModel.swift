//
//  DeviceDetailsViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

private extension Array {
    func firstOfType<T>(type: T.Type) -> T? {
        first(where: { $0 is T }).flatMap({ $0 as? T })
    }
}

// MARK: - DeviceDetailsViewModel

@MainActor final class DeviceDetailsViewModel {
    private var discoveredServices: [CBService] = []
    private var cancelable = Set<AnyCancellable>()
    
    let centralManager: CentralManager
    let peripheral: Peripheral
    
    var id: UUID { peripheral.peripheral.identifier }
    
    let environment: Environment
    private(set) var supportedServiceViewModels: [any SupportedServiceViewModel] = []
    
    private let log = NordicLog(category: "DeviceDetails.VM", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(cbPeripheral: CBPeripheral, centralManager: CentralManager) {
        self.peripheral = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
        self.centralManager = centralManager
        self.environment = Environment(deviceID: peripheral.peripheral.identifier)
        
        listenForDisconnection()
        log.debug(#function)
    }
    
    // MARK: deinit
    
    deinit {
        log.debug(#function)
    }
}

// MARK: disconnect / reconnect

extension DeviceDetailsViewModel {
    private struct TimeoutError: Error { }
    
    func onDisconnect() async {
        log.debug("Disconnect")
        supportedServiceViewModels.forEach {
            $0.onDisconnect()
        }
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
            
            await onDisconnect()
            environment.criticalError = nil
        } catch {
            
        }
        environment.reconnecting = false 
    }
}

// MARK: - Service View Models

extension DeviceDetailsViewModel {
    
    // MARK: supportedServiceViews
    
    @ViewBuilder
    func supportedServiceViews() -> some View {
        let includedServices = supportedServiceViewModels
            .filter { !($0 is BatteryViewModel) }
            .map(\.attachedView)
        ForEach(includedServices) { attachedView in
            attachedView
        }
    }
    
    // MARK: batteryServiceViewModel
    
    var batteryServiceViewModel: BatteryViewModel? {
        supportedServiceViewModels.firstOfType(type: BatteryViewModel.self)
    }
    
    // MARK: discoverSupportedServices()
    
    func discoverSupportedServices() async {
        log.debug(#function)
        do {
            discoveredServices = try await peripheral.discoverServices(serviceUUIDs: nil).firstValue
            let supportedServices = Service.supportedServices.compactMap { CBUUID(service: $0) }
            
            for service in discoveredServices where supportedServices.contains(service.uuid) {
                switch service.uuid {
                case .nordicBlinkyService:
                    supportedServiceViewModels.append(BlinkyViewModel(peripheral: peripheral, blinkyService: service))
                case .runningSpeedCadence:
                    supportedServiceViewModels.append(RunningServiceViewModel(peripheral: peripheral, runningService: service))
                case .cyclingSpeedCadence:
                    supportedServiceViewModels.append(CyclingServiceViewModel(peripheral: peripheral, cyclingService: service))
                case .healthThermometer:
                    supportedServiceViewModels.append(HealthThermometerViewModel(peripheral: peripheral, temperatureService: service))
                case .heartRate:
                    supportedServiceViewModels.append(DeviceScreen.HeartRateViewModel(peripheral: peripheral, heartRateService: service))
                case .bloodPressure:
                    supportedServiceViewModels.append(BloodPressureViewModel(peripheral: peripheral, bpsService: service))
                case .battery:
                    supportedServiceViewModels.append(BatteryViewModel(peripheral: peripheral, batteryService: service))
                case .throughputService:
                    supportedServiceViewModels.append(ThroughputViewModel(peripheral, service: service))
                case .glucoseService:
                    supportedServiceViewModels.append(GlucoseViewModel(peripheral: peripheral, glucoseService: service))
                case .continuousGlucoseMonitoringService:
                    supportedServiceViewModels.append(CGMSViewModel(peripheral: peripheral, cgmsService: service))
                case .nordicsemiUART:
                    supportedServiceViewModels.append(UARTViewModel(peripheral: peripheral, uartService: service))
                case .deviceInformation:
                    environment.deviceInfo = try await DeviceInformation(service, peripheral: peripheral)
                default:
                    break
                }
            }
            
            environment.attributeTable = try? await attributeTable()
            environment.signalViewModel = SignalChartViewModel(peripheral: peripheral)
            
            for supportedServiceViewModel in self.supportedServiceViewModels {
                await supportedServiceViewModel.onConnect()
            }
        } catch {
            environment.alertError = .servicesNotFound
        }
    }
    
    private func listenForDisconnection() {
        centralManager.disconnectedPeripheralsChannel
            .filter { [unowned self] in $0.0.identifier == self.id }    // Filter other peripherals
            .compactMap { $0.1 }                                        // Handle only disconnections with error
            .sink { [unowned self] err in
                supportedServiceViewModels.forEach {
                    $0.onDisconnect()
                }
                // Display error
                environment.criticalError = .disconnectedWithError(err)
            }
            .store(in: &cancelable)
    }
}

// MARK: - Environment

extension DeviceDetailsViewModel {
    
    @MainActor final class Environment: ObservableObject {
        
        @Published var reconnecting: Bool
        @Published var criticalError: CriticalError?
        @Published var alertError: AlertError?
        
        @Published var showInspector: Bool = false
        @Published var attributeTable: AttributeTable?
        @Published var deviceInfo: DeviceInformation?
        @Published var signalViewModel: SignalChartViewModel?
        
        let deviceID: UUID
        
        private let log = NordicLog(category: "DeviceDetailsViewModel.Environment", subsystem: "com.nordicsemi.nrf-toolbox")
        
        init(deviceID: UUID, reconnecting: Bool = false,
             criticalError: CriticalError? = nil, alertError: AlertError? = nil) {
            self.deviceID = deviceID
            self.reconnecting = reconnecting
            self.criticalError = criticalError
            self.alertError = alertError
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}

// MARK: attributeTable()

extension DeviceDetailsViewModel {
    
    func attributeTable() async throws -> AttributeTable {
        var table = AttributeTable()
        for service in discoveredServices {
            table.addService(service)
            
            let characteristics = try await peripheral.discoverCharacteristics(nil, for: service).timeout(10, scheduler: DispatchQueue.main).firstValue
            for characteristic in characteristics {
                table.addCharacteristic(characteristic, to: service)
                
                let descriptors = try await peripheral.discoverDescriptors(for: characteristic).timeout(10, scheduler: DispatchQueue.main).firstValue
                for descriptor in descriptors {
                    table.addDescriptor(descriptor, to: characteristic, in: service)
                }
            }
        }
        return table
    }
}

extension DeviceDetailsViewModel {
    
    // MARK: CriticalError
    
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

    // MARK: AlertError
    
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
