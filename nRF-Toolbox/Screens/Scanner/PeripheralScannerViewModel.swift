//
//  PeripheralScannerViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import Combine

// MARK: - PeripheralScannerViewModel

extension PeripheralScannerScreen {
    
    @MainActor
    class PeripheralScannerViewModel: ObservableObject {
        
        let centralManager: CentralManager
        let environment: Environment
        
        private var cancelables = Set<AnyCancellable>()
        
        private let log = NordicLog(category: "PeripheralScanner.VM")
        
        // MARK: init
        
        init(centralManager: CentralManager) {
            self.environment = Environment()
            self.centralManager = centralManager
            
            setupEnvironment()
            
            log.debug(#function)
        }
        
        // MARK: deinit
        
        deinit {
            log.debug(#function)
        }
        
        private func setupEnvironment() {
            environment.connect = { [weak self] device in
                await self?.tryToConnect(device: device)
            }
        }
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
    // MARK: State
    
    enum State {
        case scanning, unsupported, disabled, unauthorized
    }
    
    // MARK: ScanResult
    
    struct ScanResult: Identifiable, Equatable {
        let name: String?
        let rssi: Int
        let id: UUID
        let services: Set<Service>
        
        init(name: String?, rssi: Int, id: UUID, services: [String]) {
            self.name = name
            self.rssi = rssi
            self.id = id
            self.services = Set(services.map {
                Service.find(by: CBUUID(string: $0)) ?? Service(name: "unknown", identifier: "service-\($0)", uuidString: $0, source: "unknown")
            })
        }
        
        func extend(using scanResult: ScanResult) -> ScanResult {
            var extendedServices = services.map(\.uuidString)
            extendedServices.append(contentsOf: scanResult.services.map(\.uuidString))
            return ScanResult(name: self.name ?? scanResult.name, rssi: scanResult.rssi, id: id, services: extendedServices)
        }
        
        static func ==(lhs: ScanResult, rhs: ScanResult) -> Bool {
            return lhs.id == rhs.id
        }
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
    // MARK: tryToConnect(device:)
    
    func tryToConnect(device: ScanResult) async {
        if environment.connectingDevice != nil {
            return
        }
        
        environment.connectingDevice = device
        
        // Get CBPeripheral's instance
        let peripheral = centralManager.retrievePeripherals(withIdentifiers: [device.id]).first!
        
        do {
            // `connect` method returns Publisher that sends connected CBPeripheral
            _ = try await centralManager.connect(peripheral).first().firstValue
        } catch let error {
            environment.error = ReadableError(error)
        }
        
        environment.connectingDevice = nil
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
    // MARK: setupManager()
    
    func setupManager() {
        guard cancelables.isEmpty else { return }
        // Track state CBCentralManager's state changes
        centralManager.stateChannel
            .map { state -> State in
                switch state {
                case .poweredOff: return .disabled
                case .unauthorized: return .unauthorized
                case .unsupported: return .unsupported
                default: return .scanning
                }
            }
            .assign(to: &environment.$state)
        
        
        guard centralManager.centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil)
            // Filter unnamed and unconnectable devices
            .filter { $0.name != nil && $0.advertisementData.isConnectable == true }
            .map { result -> ScanResult in
                ScanResult(
                    name: result.name,
                    rssi: result.rssi.value,
                    id: result.peripheral.identifier,
                    services: result.advertisementData.serviceUUIDs?.compactMap { $0.uuidString } ?? []
                )
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    self.environment.error = ReadableError(error)
                }
            } receiveValue: { result in
                if let i = self.environment.devices.firstIndex(where: \.id, equals: result.id) {
                    let existingDevice = self.environment.devices[i]
                    self.environment.devices[i] = existingDevice.extend(using: result)
                } else {
                    self.environment.devices.append(result)
                }
            }
            .store(in: &cancelables)
    }
    
    // MARK: refresh()
    
    func refresh() {
        centralManager.stopScan()
        environment.devices.removeAll()
        cancelables.removeAll()
        setupManager()
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
    // MARK: Environment
    
    class Environment: ObservableObject {
        
        // MARK: Properties
        
        @Published fileprivate(set) var error: ReadableError?
        @Published fileprivate(set) var devices: [ScanResult]
        @Published fileprivate(set) var connectingDevice: ScanResult?
        @Published fileprivate(set) var state: State
        
        fileprivate(set) var connect: (ScanResult) async -> ()
        
        private let log = NordicLog(category: "PeripheralScanner.Env")
        
        // MARK: init
        
        init(error: ReadableError? = nil, devices: [ScanResult] = [], connectingDevice: ScanResult? = nil, state: State = .disabled, connect: @escaping (ScanResult) -> Void = { _ in}) {
            self.error = error
            self.devices = devices
            self.connectingDevice = connectingDevice
            self.state = state
            self.connect = connect
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}
