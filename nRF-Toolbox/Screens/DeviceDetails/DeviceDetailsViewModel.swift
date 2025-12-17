//
//  DeviceDetailsViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine
import CoreBluetoothMock
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

@MainActor
final class DeviceDetailsViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private var discoveredServices: [CBService] = []
    private var cancellable = Set<AnyCancellable>()
    
    let centralManager: CentralManager
    let peripheral: Peripheral
    
    var id: UUID { peripheral.peripheral.identifier }
    
    @Published
    var errors: ErrorsHolder = ErrorsHolder()
    
    @Published
    var device: ConnectedDevicesViewModel.Device
    
    private(set) var supportedServiceViewModels: [any SupportedServiceViewModel] = []
    
    private let log = NordicLog(category: "DeviceDetails.VM", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published var showDeviceSheet: Bool = false
    @Published var attributeTable: AttributeTable?
    @Published var deviceInfo: DeviceInformation?
    @Published var signalViewModel: SignalChartViewModel?
    @Published var isInitialized: Bool = false
    
    // MARK: init
    
    init(cbPeripheral: CBPeripheral, centralManager: CentralManager, device: ConnectedDevicesViewModel.Device) {
        self.peripheral = Peripheral(peripheral: cbPeripheral, delegate: ReactivePeripheralDelegate())
        self.centralManager = centralManager
        self.device = device
        
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
    
    func reconnect() async {
        log.debug(#function)
        do {
            _ = try await centralManager.connect(peripheral.peripheral)
                // Set timeout for 5 seconds
                .timeout(5, scheduler: DispatchQueue.main, customError: {
                    TimeoutError()
                })
                .firstValue
        } catch {
            log.error("\(#function) Error: \(error.localizedDescription)")
            await onDisconnect()
        }
    }
    
    func onDisconnect() async {
        log.debug(#function)
        signalViewModel?.stopTimer()
        supportedServiceViewModels.forEach {
            $0.onDisconnect()
        }
        peripheral.peripheral.delegate = nil
    }
}

// MARK: - Service View Models

extension DeviceDetailsViewModel {
    
    // MARK: supportedServiceViews
    
    @ViewBuilder
    func supportedServiceViews() -> some View {
        let includedViews = supportedServiceViewModels
            .filter { !($0 is BatteryViewModel) }
            .map { viewModel in
                Section(viewModel.description) {
                    AnyView(viewModel.attachedView)
                }
            }

        ForEach(0..<includedViews.count, id: \.self) { index in
            includedViews[index]
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
            if supportedServiceViewModels.hasItems {
                await onDisconnect()
                supportedServiceViewModels.removeAll()
            }
            discoveredServices = try await peripheral.discoverServices(serviceUUIDs: nil).firstValue

            var table = AttributeTable()
            for service in discoveredServices {
                table.addService(service)

                let characteristics: [CBCharacteristic] = try await peripheral.discoverCharacteristics(nil, for: service).firstValue
                for characteristic in characteristics {
                    table.addCharacteristic(characteristic, to: service)
                    
                    let descriptors = try await peripheral.discoverDescriptors(for: characteristic).firstValue
                    for descriptor in descriptors {
                        table.addDescriptor(descriptor, to: characteristic, in: service)
                    }
                }
                
                switch service.uuid {
                case .nordicBlinkyService:
                    supportedServiceViewModels.append(BlinkyViewModel(peripheral: peripheral, characteristics: characteristics))
                case .runningSpeedCadence:
                    supportedServiceViewModels.append(RunningServiceViewModel(peripheral: peripheral, characteristics: characteristics))
                case .cyclingSpeedCadence:
                    supportedServiceViewModels.append(CyclingServiceViewModel(peripheral: peripheral, characteristics: characteristics))
                case .healthThermometer:
                    supportedServiceViewModels.append(HealthThermometerViewModel(peripheral: peripheral, characteristics: characteristics))
                case .heartRate:
                    supportedServiceViewModels.append(HeartRateViewModel(peripheral: peripheral, characteristics: characteristics))
                case .bloodPressure:
                    supportedServiceViewModels.append(BloodPressureViewModel(peripheral: peripheral, characteristics: characteristics))
                    let cuffCharacteristics: [CBCharacteristic] = characteristics.filter { cbChar in
                        cbChar.uuid == Characteristic.intermediateCuffPressure.uuid
                    }
                    if cuffCharacteristics.hasItems {
                        supportedServiceViewModels.append(CuffPressureViewModel(peripheral: peripheral, characteristics: characteristics))
                    }
                case .battery:
                    supportedServiceViewModels.append(BatteryViewModel(peripheral: peripheral, characteristics: characteristics))
                case .throughputService:
                    supportedServiceViewModels.append(ThroughputViewModel(peripheral, characteristics: characteristics))
                case .glucoseService:
                    supportedServiceViewModels.append(GlucoseViewModel(peripheral: peripheral, characteristics: characteristics))
                case .continuousGlucoseMonitoringService:
                    supportedServiceViewModels.append(CGMSViewModel(peripheral: peripheral, characteristics: characteristics))
                case .nordicsemiUART:
                    supportedServiceViewModels.append(UARTViewModel(peripheral: peripheral, characteristics: characteristics))
                case .deviceInformation:
                    deviceInfo = try await DeviceInformation(characteristics, peripheral: peripheral)
                default:
                    break
                }
            }
            
            attributeTable = table
            
            signalViewModel = SignalChartViewModel(peripheral: peripheral)
            signalViewModel?.startTimer()
            
            for supportedServiceViewModel in self.supportedServiceViewModels {
                await supportedServiceViewModel.onConnect()
                
                supportedServiceViewModel.errors
                    .drop(while: { value in // Default values from other services may override an actual error.
                        !value.hasAnyError()
                    })
                    .sink { error in
                        self.errors = error
                    }.store(in: &cancellable)
            }
            isInitialized = true
        } catch {
            errors.error = AlertError.servicesNotFound
            log.error("\(#function) Error: \(error.localizedDescription)")
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
                signalViewModel?.stopTimer()
            }
            .store(in: &cancellable)
    }
}

extension DeviceDetailsViewModel {

    // MARK: AlertError
    
    enum AlertError: LocalizedError {
        case servicesNotFound

        var description: String? {
            switch self {
            case .servicesNotFound:
                return "Services not found"
            }
        }

        var errorDescription: String? {
            switch self {
            case .servicesNotFound:
                return "Error occured while discovering services."
            }
        }
    }
}
