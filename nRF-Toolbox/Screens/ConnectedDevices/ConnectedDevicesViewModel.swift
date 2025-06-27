//
//  ConnectedDevicesViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 11/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import iOS_BLE_Library_Mock
import Combine
import iOS_Bluetooth_Numbers_Database

// MARK: - ConnectedDevicesViewModel

@MainActor
final class ConnectedDevicesViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let centralManager: CentralManager
    private var deviceViewModels: [UUID: DeviceDetailsViewModel] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "HeartRateScreen", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published fileprivate(set) var connectedDevices: [Device]
    @Published var selectedDevice: Device? {
        didSet {
            if let d = connectedDevices.first(where: { $0 == selectedDevice }) {
                print(d.name!)
            } else {
                print("no selection")
            }
        }
    }
    
    @Published var showUnexpectedDisconnectionAlert: Bool = false
    @Published fileprivate(set) var unexpectedDisconnectionMessage: String = ""
    
    var hasSelectedDevice: Bool {
        selectedDevice != nil
    }
    
    // MARK: init
    
    init(centralManager: CentralManager) {
        self.centralManager = centralManager
        self.connectedDevices = []
        self.selectedDevice = nil
        observeStateChange()
        observeConnections()
        observeDisconnections()
        log.debug(#function)
    }
}

extension ConnectedDevicesViewModel {
    
    // MARK: selectedDeviceModel()
    
    func selectedDeviceModel() -> DeviceDetailsViewModel? {
        guard let selectedDevice else { return nil }
        return deviceViewModel(for: selectedDevice.id)
    }
    
    // MARK: deviceViewModel(for:)
    
    func deviceViewModel(for deviceID: Device.ID) -> DeviceDetailsViewModel? {
        guard let deviceViewModel = deviceViewModels[deviceID] else {
            // Can return 'nil' after disconnect
            return nil
        }
        return deviceViewModel
    }
    
    // MARK: disconnectAndRemoveViewModel()
    
    func disconnectAndRemoveViewModel(_ deviceID: Device.ID) async throws {
        log.debug(#function)
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [deviceID]).first else { return }
        guard let deviceViewModel = deviceViewModels[deviceID] else { return }
        
        await deviceViewModel.onDisconnect()
        if let i = connectedDevices.firstIndex(where: \.id, equals: deviceID) {
            connectedDevices[i].status = .userInitiatedDisconnection
        }
        
        defer {
            clearViewModel(deviceID)
        }
        
//        if case .disconnectedWithError = deviceViewModel.environment.criticalError {
//            return
//        }
        
        do {
            _ = try await centralManager.cancelPeripheralConnection(peripheral).firstValue
        } catch {
            log.error(error.localizedDescription)
        }
    }
    
    // MARK: clearViewModel(:)
    
    func clearViewModel(_ deviceID: Device.ID) {
        log.debug(#function)
        connectedDevices.removeAll(where: { $0.id == deviceID })
        deviceViewModels.removeValue(forKey: deviceID)
    }
}

extension ConnectedDevicesViewModel {
    
    // MARK: observeStateChange()
    
    private func observeStateChange() {
        log.debug(#function)
        centralManager.stateChannel
            .sink { [log, weak self] state in
                log.debug("BLE State changed to \(state).")
                switch state {
                case .poweredOff, .unauthorized, .unsupported:
                    guard let self else { return }
                    for i in connectedDevices.indices {
                        connectedDevices[i].status = .error(ConnectionError.bluetoothUnavailable)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: observeConnections()
    
    private func observeConnections() {
        log.debug(#function)
        centralManager.connectedPeripheralChannel
            .map { $0 } // Remove <Never> as $1
            .filter { $0.1 == nil } // No connection error
            .map { (peripheral: CBPeripheral, error: Error?) -> Device in
                let services = Set<Service>(peripheral.services?.compactMap {
                    Service.find(by: $0.uuid) ?? Service(name: "unknown", identifier: "service-\($0.uuid.uuidString)", uuidString: $0.uuid.uuidString, source: "unknown")
                } ?? [])
                
                return Device(name: peripheral.name, id: peripheral.identifier,
                              services: services, status: .connected)
            }
            .sink { [unowned self] device in
                if let i = connectedDevices.firstIndex(where: \.id, equals: device.id) {
                    connectedDevices[i] = device
                } else {
                    connectedDevices.append(device)
                }
                
                if deviceViewModels[device.id] == nil,
                   let peripheral = centralManager.retrievePeripherals(withIdentifiers: [device.id]).first {
                    
                    let viewModel = DeviceDetailsViewModel(cbPeripheral: peripheral, centralManager: centralManager)
                    deviceViewModels[device.id] = viewModel
                }
                
                guard !hasSelectedDevice else { return }
                selectedDevice = device
            }
            .store(in: &cancellables)
    }
    
    // MARK: observeDisconnections()
    
    private func observeDisconnections() {
        log.debug(#function)
        centralManager.disconnectedPeripheralsChannel
            .sink { [unowned self] (peripheral, error) in
                guard let i = self.connectedDevices.firstIndex(where: \.id, equals: peripheral.identifier) else {
                    return
                }
                
                let disconnectedDevice = self.connectedDevices[i]
                self.log.debug("Disconnected Device Status: \(disconnectedDevice.status)")
                if let error {
                    self.connectedDevices[i].status = .error(error)
                } else {
                    self.connectedDevices.remove(at: i)
                }
                
                if disconnectedDevice.status.hashValue != ConnectedDevicesViewModel.Device.Status.userInitiatedDisconnection.hashValue {
                    self.showUnexpectedDisconnectionAlert = true
                    self.unexpectedDisconnectionMessage = "\(disconnectedDevice.name ?? "Unnamed Device") disconnected unexpectedly."
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - ConnectionError

extension ConnectedDevicesViewModel {
    
    enum ConnectionError: LocalizedError {
        case bluetoothUnavailable
        
        var errorDescription: String? {
            return "Bluetooth is powered off or is unavailable."
        }
    }
}

// MARK: - Device

extension ConnectedDevicesViewModel {
    
    struct Device: Identifiable, CustomStringConvertible, CustomDebugStringConvertible, Hashable, Equatable {
        
        // MARK: Status
        
        enum Status: CustomStringConvertible {
            case connected
            case userInitiatedDisconnection
            case error(_: Error)
            
            var description: String {
                switch self {
                case .connected:
                    return "Connected"
                case .userInitiatedDisconnection:
                    return "User initiated disconnection"
                case .error(let error):
                    return "Error: \(error.localizedDescription)"
                }
            }
            
            var hashValue: Int {
                switch self {
                case .connected:
                    return 0
                case .userInitiatedDisconnection:
                    return 1
                case .error:
                    return 99
                }
            }
        }
        
        // MARK: Properties
        
        let name: String?
        let id: UUID
        let services: Set<Service>
        var status: Status
        var description: String { name ?? "Unnamed" }
        var debugDescription: String { description }
        
        // MARK: init
        
        init(name: String?, id: UUID, services: Set<Service>, status: Status) {
            self.name = name
            self.id = id
            self.services = services
            self.status = status
        }
        
        // MARK: Equatable
        
        static func == (lhs: Device, rhs: Device) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        // MARK: Hashable
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(status.hashValue)
        }
    }
}
