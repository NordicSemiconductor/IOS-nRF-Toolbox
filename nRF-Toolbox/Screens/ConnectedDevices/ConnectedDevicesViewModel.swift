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
    
    private var deviceViewModels: [UUID: DeviceDetailsScreen.DeviceDetailsViewModel] = [:]
    private var cancelable = Set<AnyCancellable>()
    
    lazy var environment: Environment = Environment(deviceViewModel: {
        [unowned self] in self.deviceViewModel(for: $0.id)!
    })
    let centralManager: CentralManager
    
    var hasSelectedDevice: Bool {
        environment.selectedDevice != .Unselected
    }
    
    private let log = NordicLog(category: "HeartRateScreen", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(centralManager: CentralManager) {
        self.centralManager = centralManager
        observeConnections()
        observeDisconnections()
        log.debug(#function)
    }
}

extension ConnectedDevicesViewModel {
    
    func selectedDeviceModel() -> DeviceDetailsScreen.DeviceDetailsViewModel? {
        guard environment.selectedDevice != .Unselected else { return nil }
        return deviceViewModel(for: environment.selectedDevice.id)
    }
    
    // MARK: deviceViewModel(for:)
    
    func deviceViewModel(for deviceID: Device.ID) -> DeviceDetailsScreen.DeviceDetailsViewModel? {
        if let vm = deviceViewModels[deviceID] {
            return vm
        } else {
            guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [deviceID]).first else {
                return nil
            }
            let newViewModel = DeviceDetailsScreen.DeviceDetailsViewModel(cbPeripheral: peripheral, centralManager: centralManager)
            deviceViewModels[deviceID] = newViewModel
            return newViewModel
        }
    }
    
    // MARK: disconnectAndRemoveViewModel()
    
    func disconnectAndRemoveViewModel(_ deviceID: Device.ID) async throws {
        log.debug(#function)
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [deviceID]).first else { return }
        guard let vm = deviceViewModels[deviceID] else { return }
        
        if let i = environment.connectedDevices.firstIndex(where: \.id, equals: deviceID) {
            environment.connectedDevices[i].status = .busy
        }
        
        if case .disconnectedWithError = vm.environment.criticalError {
            environment.connectedDevices.removeAll(where: { $0.id == deviceID })
        } else {
            _ = try await centralManager.cancelPeripheralConnection(peripheral).firstValue
        }
        
        environment.connectedDevices.removeAll(where: { $0.id == deviceID })
        deviceViewModels.removeValue(forKey: deviceID)
        vm.onDisconnect()
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
                if let i = self.environment.connectedDevices.firstIndex(where: \.id, equals: device.id) {
                    self.environment.connectedDevices[i] = device
                } else {
                    self.environment.connectedDevices.append(device)
                }
                
                guard !hasSelectedDevice else { return }
                self.environment.selectedDevice = device
            }
            .store(in: &cancelable)
    }
    
    // MARK: observeDisconnections()
    
    private func observeDisconnections() {
        centralManager.disconnectedPeripheralsChannel
            .sink { [unowned self] device in
                guard let deviceIndex = self.environment.connectedDevices.firstIndex(where: {
                    $0.id == device.0.identifier }) else {
                    return
                }
                
                if let err = device.1 {
                    self.environment.connectedDevices[deviceIndex].status = .error(err)
                } else {
                    self.environment.connectedDevices.remove(at: deviceIndex)
                }
            }
            .store(in: &cancelable)
    }
}

// MARK: - Device

extension ConnectedDevicesViewModel {
    
    struct Device: Identifiable, CustomStringConvertible, CustomDebugStringConvertible, Hashable, Equatable {
        
        static let Unselected = Device(name: "Unselected", id: UUID(), services: [], status: .connected)
        
        // MARK: Status
        
        enum Status {
            case busy
            case connected
            case error(_: Error)
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
            lhs.id == rhs.id
        }
        
        // MARK: Hashable
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

// MARK: - Environment

extension ConnectedDevicesViewModel {
    
    final class Environment: ObservableObject {
        
        @Published var showScanner: Bool = false
        @Published fileprivate(set) var connectedDevices: [Device]
        @Published var selectedDevice: Device {
            didSet {
                if let d = connectedDevices.first(where: { $0 == selectedDevice }) {
                    print(d.name!)
                } else {
                    print("no selection")
                }
            }
        }
        
        let deviceViewModel: ((Device) -> (DeviceDetailsScreen.DeviceDetailsViewModel))?
        
        init(deviceViewModel: ((Device) -> (DeviceDetailsScreen.DeviceDetailsViewModel))? = nil) {
            self.deviceViewModel = deviceViewModel
            self.connectedDevices = [.Unselected]
            self.selectedDevice = .Unselected
        }
    }
}
