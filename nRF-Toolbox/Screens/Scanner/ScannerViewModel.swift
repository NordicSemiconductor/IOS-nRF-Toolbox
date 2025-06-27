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

// MARK: - ScannerViewModel

@MainActor
final class ScannerViewModel: ObservableObject {
    
    // MARK: State
    
    enum ScannerState {
        case scanning, unsupported, disabled, unauthorized
    }
    
    // MARK: Properties
    
    private let centralManager: CentralManager
    
    @Published fileprivate(set) var error: ReadableError?
    @Published fileprivate(set) var devices: [ConnectedDevicesViewModel.ScanResult]
    @Published fileprivate(set) var connectingDevice: ConnectedDevicesViewModel.ScanResult?
    @Published fileprivate(set) var scannerState: ScannerState
    
    private var cancellables = Set<AnyCancellable>()
    private let log = NordicLog(category: "PeripheralScanner.VM")
    
    // MARK: init
    
    init(centralManager: CentralManager) {
        self.centralManager = centralManager
        
        self.error = nil
        self.devices = []
        self.connectingDevice = nil
        self.scannerState = .disabled
        
        log.debug(#function)
    }
    
    // MARK: adv
    
    func advertisedServices(_ deviceID: UUID) -> Set<Service> {
        return devices
            .first(where: \.id, isEqualsTo: deviceID)?
            .services ?? Set<Service>()
    }
    
    // MARK: deinit
    
    deinit {
        log.debug(#function)
    }
}

extension ScannerViewModel {
    
    // MARK: tryToConnect(device:)
    
    @MainActor
    func tryToConnect(device: ConnectedDevicesViewModel.ScanResult) async {
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

extension ScannerViewModel {
    
    // MARK: setupManager()
    
    func setupManager() {
        log.debug(#function)
        guard cancellables.isEmpty else { return }
        // Track state CBCentralManager's state changes
        centralManager.stateChannel
            .map { state -> ScannerState in
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
            .assign(to: &$scannerState)
        
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
            .map { result -> ConnectedDevicesViewModel.ScanResult in
                ConnectedDevicesViewModel.ScanResult(
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
