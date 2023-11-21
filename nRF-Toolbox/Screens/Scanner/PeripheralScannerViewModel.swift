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
import Combine

extension PeripheralScannerScreen {
    @MainActor
    class ViewModel: ObservableObject {
        let centralManager: CentralManager
        let environment: PreviewEnvironment
        
        private var cancelables = Set<AnyCancellable>()
        
        init(centralManager: CentralManager) {
            self.environment = PreviewEnvironment()
            self.centralManager = centralManager
            
            setupEnvironment()
            
            print("created VM")
        }
        
        deinit {
            print("destroyed VM")
        }
        
        private func setupEnvironment() {
            environment.connect = { [weak self] device in
                await self?.tryToConnect(device: device)
            }
        }
    }
}

extension PeripheralScannerScreen.ViewModel {
    enum State {
        case scanning, unsupported, disabled, unauthorized
    }
    
    struct ScanResult: Identifiable, Equatable {
        let name: String?
        let rssi: Int
        let id: UUID
        
        let services: [Service]
        
        init(name: String?, rssi: Int, id: UUID, services: [String]) {
            self.name = name
            self.rssi = rssi
            self.id = id
            self.services = services.map {
                Service.find(by: CBUUID(string: $0)) ?? Service(name: "unknown", identifier: "service-\($0)", uuidString: $0, source: "unknown")
            }
        }
        
        static func ==(lhs: ScanResult, rhs: ScanResult) -> Bool {
            return lhs.id == rhs.id
        }
    }
}

extension PeripheralScannerScreen.ViewModel {
    func tryToConnect(device: ScanResult) async {
        if environment.connectingDevice != nil {
            return
        }
        
        environment.connectingDevice = device
        
        let peripheral = centralManager.retrievePeripherals(withIdentifiers: [device.id]).first!
        
        do {
            _ = try await centralManager.connect(peripheral).first().value
        } catch let e {
            environment.error = ReadableError(error: e)
        }
        
        environment.connectingDevice = nil
    }
}

extension PeripheralScannerScreen.ViewModel {
    func setupManager() {
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
        
        centralManager.scanForPeripherals(withServices: nil)
            .filter { $0.name != nil }
            .map { sr -> ScanResult in
                ScanResult(
                    name: sr.name,
                    rssi: sr.rssi.value,
                    id: sr.peripheral.identifier,
                    services: sr.advertisementData.serviceUUIDs?.compactMap { $0.uuidString } ?? []
                )
            }
            .sink { completion in
                if case .failure(let e) = completion {
                    self.environment.error = ReadableError(error: e)
                }
            } receiveValue: { sr in
                self.environment.devices.replacedOrAppended(sr)
            }
            .store(in: &cancelables)
    }
}

extension PeripheralScannerScreen.ViewModel {
    class PreviewEnvironment: ObservableObject {
        @Published fileprivate (set) var error: ReadableError?
        @Published fileprivate (set) var devices: [ScanResult]
        @Published fileprivate (set) var connectingDevice: ScanResult?
        @Published fileprivate (set) var state: State
        
        fileprivate (set) var connect: (ScanResult) async -> ()
        
        init(error: ReadableError? = nil, devices: [ScanResult] = [], connectingDevice: ScanResult? = nil, state: State = .disabled, connect: @escaping (ScanResult) -> Void = { _ in}) {
            self.error = error
            self.devices = devices
            self.connectingDevice = connectingDevice
            self.state = state
            self.connect = connect
        }
    }
}
