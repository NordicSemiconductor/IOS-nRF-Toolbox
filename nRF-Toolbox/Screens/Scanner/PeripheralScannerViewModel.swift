//
//  PeripheralScannerViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import Combine

extension PeripheralScannerScreen {
    @MainActor
    class ViewModel: ObservableObject {
        let centralManager: CentralManager
        let environment: PreviewEnvironment
        
        private var cancelables = Set<AnyCancellable>()
        
        init(centralManager: CentralManager) {
            self.environment = PreviewEnvironment(devices: [], connect: { sr in
                Task {
                    await self.tryToConnect(device: sr)
                }
            })
            self.centralManager = centralManager
            
            setupManager(centralManager: centralManager)
            
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
        
        let services: [String]
        
        var knownServices: [ServiceRepresentation] {
            services.compactMap { ServiceRepresentation(identifier: $0) }
        }
        
        init(name: String?, rssi: Int, id: UUID, services: [String]) {
            self.name = name
            self.rssi = rssi
            self.id = id
            self.services = services
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
            let connected = try await centralManager.connect(peripheral).first().value
        } catch let e {
            environment.error = ReadableError(error: e)
        }
        
        environment.connectingDevice = nil
    }
}

extension PeripheralScannerScreen.ViewModel {
    private func setupManager(centralManager: CentralManager) {
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
        
        let connect: (ScanResult) -> ()
        
        init(error: ReadableError? = nil, devices: [ScanResult] = [], connectingDevice: ScanResult? = nil, state: State = .disabled, connect: @escaping (ScanResult) -> Void = { _ in}) {
            self.error = error
            self.devices = devices
            self.connectingDevice = connectingDevice
            self.state = state
            self.connect = connect
        }
    }
}
