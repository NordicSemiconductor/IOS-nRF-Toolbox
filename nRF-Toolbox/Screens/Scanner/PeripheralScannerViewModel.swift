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
import CoreBluetoothMock

// MARK: - PeripheralScannerViewModel

extension PeripheralScannerScreen {
    
    @MainActor
    final class PeripheralScannerViewModel: ObservableObject {
        
        // MARK: State
        
        enum State {
            case scanning, unsupported, disabled, unauthorized
        }
        
        // MARK: Properties
        
        private let centralManager: CentralManager
        
        @Published fileprivate(set) var error: ReadableError?
        @Published fileprivate(set) var devices: [ScanResult]
        @Published fileprivate(set) var connectingDevice: ScanResult?
        @Published fileprivate(set) var state: State
        
        private var cancellables = Set<AnyCancellable>()
        private let log = NordicLog(category: "PeripheralScanner.VM")
        
        // MARK: init
        
        init(centralManager: CentralManager) {
            self.centralManager = centralManager
            
            self.error = nil
            self.devices = []
            self.connectingDevice = nil
            self.state = .disabled
            
            log.debug(#function)
        }
        
        // MARK: deinit
        
        deinit {
            log.debug(#function)
        }
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
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
                Service.extendedFind(by: $0) ?? Service(name: "unknown", identifier: "service-\($0)", uuidString: $0, source: "unknown")
            })
        }
        
        func extend(using scanResult: ScanResult) -> ScanResult {
            var extendedServices = services.map(\.uuidString)
            extendedServices.append(contentsOf: scanResult.services.map(\.uuidString))
            return ScanResult(name: scanResult.name ?? self.name, rssi: scanResult.rssi,
                              id: id, services: extendedServices)
        }
        
        static func ==(lhs: ScanResult, rhs: ScanResult) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    func advertisedServices(_ deviceID: UUID) -> Set<Service> {
        return devices
            .first(where: \.id, isEqualsTo: deviceID)?
            .services ?? Set<Service>()
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
    // MARK: tryToConnect(device:)
    
    @MainActor
    func tryToConnect(device: ScanResult) async {
        log.debug(#function)
        if connectingDevice != nil {
            return
        }
        
        connectingDevice = device
        // Get CBPeripheral's instance
        let peripheral = centralManager.retrievePeripherals(withIdentifiers: [device.id]).first!
        
        do {
            // `connect` method returns Publisher that sends connected CBPeripheral
            _ = try await centralManager.connect(peripheral).first().firstValue
        } catch let error {
            self.error = ReadableError(error)
        }
        
        connectingDevice = nil
    }
}

extension PeripheralScannerScreen.PeripheralScannerViewModel {
    
    // MARK: setupManager()
    
    func setupManager() {
        log.debug(#function)
        guard cancellables.isEmpty else { return }
        // Track state CBCentralManager's state changes
        centralManager.stateChannel
            .map { state -> State in
                switch state {
                case .poweredOff:
                    return .disabled
                case .unauthorized:
                    return .unauthorized
                case .unsupported:
                    return .unsupported
                default:
                    return .scanning
                }
            }
            .assign(to: &$state)
        
        guard centralManager.centralManager.state == .poweredOn else { return }
    }
    
    // MARK: startScanning()
    
    func startScanning() {
        log.debug(#function)
        guard centralManager.centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil)
            .filter {
                // Filter unconnectable devices
                return $0.advertisementData.isConnectable == true
            }
            .map { result -> ScanResult in
                ScanResult(
                    name: result.advertisementData.localName ?? result.name,
                    rssi: result.rssi.value,
                    id: result.peripheral.identifier,
                    services: result.advertisementData.serviceUUIDs?.compactMap { $0.uuidString } ?? []
                )
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    self.error = ReadableError(error)
                }
            } receiveValue: { result in
                if let i = self.devices.firstIndex(where: \.id, equals: result.id) {
                    let existingDevice = self.devices[i]
                    self.devices[i] = existingDevice.extend(using: result)
                } else {
                    self.devices.append(result)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: stopScanning()
    
    func stopScanning() {
        log.debug(#function)
        centralManager.stopScan()
        cancellables.removeAll()
    }
    
    // MARK: refresh()
    
    func refresh() {
        stopScanning()
        devices.removeAll()
        setupManager()
        startScanning()
    }
}
