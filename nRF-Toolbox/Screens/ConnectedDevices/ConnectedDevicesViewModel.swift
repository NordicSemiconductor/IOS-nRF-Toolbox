//
//  ConnectedDevicesViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 11/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library_Mock
import Combine

@MainActor
class ConnectedDevicesViewModel: ObservableObject {
    typealias ScannerVM = PeripheralScannerScreen.PeripheralScannerViewModel
    
    private var deviceViewModels: [UUID: DeviceDetailsScreen.DeviceDetailsViewModel] = [:]
    private var cancelable = Set<AnyCancellable>()
    
    private(set) lazy var environment: Environment = Environment(deviceViewModel: {
        [unowned self] in self.deviceViewModel(for: $0.id)!
    })
    let centralManager: CentralManager
    
    init(centralManager: CentralManager = CentralManager()) {
        self.centralManager = centralManager
        
        observeConnections()
        observeDisconnections()
    }
}

extension ConnectedDevicesViewModel {
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
    
    func disconnectAndRemoveViewModel(_ deviceID: Device.ID) async throws {
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [deviceID]).first else { return }
        guard let vm = deviceViewModels[deviceID] else { return }
        
        if case .disconnectedWithError = vm.environment.criticalError {
            environment.connectedDevices.removeAll(where: { $0.id == deviceID })
        } else {
            _ = try await centralManager.cancelPeripheralConnection(peripheral).firstValue
        }
        
        self.deviceViewModels.removeValue(forKey: deviceID)
        vm.onDisconnect()
    }
}

extension ConnectedDevicesViewModel {
    private func observeConnections() {
        centralManager.connectedPeripheralChannel
            .filter { $0.1 == nil } // No connection error
            .map { Device(name: $0.0.name, id: $0.0.identifier) }
            .sink { [unowned self] device in
                if let i = self.environment.connectedDevices.firstIndex(where: {
                    $0.id == device.id
                }) {
                    self.environment.connectedDevices[i] = device
                } else {
                    self.environment.connectedDevices.append(device)
                }
//                self.environment.connectedDevices.replacedOrAppended(device)
            }
            .store(in: &cancelable)
    }
    
    private func observeDisconnections() {
        centralManager.disconnectedPeripheralsChannel
            .sink { [unowned self] device in
                guard let deviceIndex = self.environment.connectedDevices.firstIndex(where: { $0.id == device.0.identifier }) else {
                    return
                }
                
                if let err = device.1 {
                    self.environment.connectedDevices[deviceIndex].error = err
                } else {
                    self.environment.connectedDevices.remove(at: deviceIndex)
                }
            }
            .store(in: &cancelable)
    }
}

extension ConnectedDevicesViewModel {
    struct Device: Identifiable, Equatable, Hashable {
        let name: String?
        let id: UUID
        var error: Error?
        
        static func == (lhs: Device, rhs: Device) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    class Environment: ObservableObject {
        @Published var showScanner: Bool = false
        
        @Published fileprivate(set) var connectedDevices: [Device]
        @Published var selectedDevice: Device.ID? {
            didSet {
                if let d = connectedDevices.first(where: { $0.id == selectedDevice }) {
                    print(d.name!)
                } else {
                    print("no selection")
                }
            }
        }
        
        let deviceViewModel: ((Device) -> (DeviceDetailsScreen.DeviceDetailsViewModel))?
        
        init(
            connectedDevices: [Device] = [],
            deviceViewModel: ((Device) -> (DeviceDetailsScreen.DeviceDetailsViewModel))? = nil
        ) {
            self.connectedDevices = connectedDevices
            self.deviceViewModel = deviceViewModel
        }
    }
}
