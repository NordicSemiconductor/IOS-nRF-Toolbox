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
    typealias ScannerVM = PeripheralScannerScreen.PeripheralScannerViewModel
    
    private var deviceViewModels: [UUID: DeviceDetailsViewModel] = [:]
    private var cancelable = Set<AnyCancellable>()
    
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
    
    let centralManager: CentralManager
    
    var hasSelectedDevice: Bool {
        selectedDevice != nil
    }
    
    private let log = NordicLog(category: "HeartRateScreen", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(centralManager: CentralManager) {
        self.centralManager = centralManager
        self.connectedDevices = []
        self.selectedDevice = nil
        observeConnections()
        observeDisconnections()
        log.debug(#function)
    }
}

extension ConnectedDevicesViewModel {
    
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
            connectedDevices[i].status = .busy
        }
        
        defer {
            connectedDevices.removeAll(where: { $0.id == deviceID })
            deviceViewModels.removeValue(forKey: deviceID)
        }
        
        if case .disconnectedWithError = deviceViewModel.environment.criticalError {
            return
        }
        
        do {
            _ = try await centralManager.cancelPeripheralConnection(peripheral).firstValue
        } catch {
            log.error(error.localizedDescription)
        }
    }
}

extension ConnectedDevicesViewModel {
    
    // MARK: observeConnections()
    
    private func observeConnections() {
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
                
                if deviceViewModels[device.id] == nil, let peripheral = centralManager.retrievePeripherals(withIdentifiers: [device.id]).first {
                    let viewModel = DeviceDetailsViewModel(cbPeripheral: peripheral, centralManager: centralManager)
                    deviceViewModels[device.id] = viewModel
                }
                
                guard !hasSelectedDevice else { return }
                selectedDevice = device
            }
            .store(in: &cancelable)
    }
    
    // MARK: observeDisconnections()
    
    private func observeDisconnections() {
        centralManager.disconnectedPeripheralsChannel
            .sink { [unowned self] device in
                guard let i = self.connectedDevices.firstIndex(where: \.id, equals: device.0.identifier) else {
                    return
                }
                
                let disconnectedDevice = self.connectedDevices[i]
                if let err = device.1 {
                    self.connectedDevices[i].status = .error(err)
                } else {
                    self.connectedDevices.remove(at: i)
                }
                if selectedDevice?.id == disconnectedDevice.id {
                    self.selectedDevice = nil
                }
            }
            .store(in: &cancelable)
    }
}

// MARK: - Device

extension ConnectedDevicesViewModel {
    
    struct Device: Identifiable, CustomStringConvertible, CustomDebugStringConvertible, Hashable, Equatable {
        
        // MARK: Status
        
        enum Status {
            case connected
            case busy
            case error(_: Error)
            
            var hashValue: Int {
                switch self {
                case .connected:
                    return 0
                case .busy:
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
