//
//  PeripheralViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 30/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

private typealias ViewModel = PeripheralInspectorViewModel

@MainActor final class PeripheralInspectorViewModel {
    
    let env: Environment
    private static let batteryLevelDataLength = 120

    private var cancellables = Set<AnyCancellable>()
    
    private let peripheral: Peripheral
    
    private let log = NordicLog(category: "PeripheralInspectorViewModel")
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
        self.env = Environment(
            deviceId: peripheral.peripheral.identifier,
            signalChartViewModel: SignalChartScreen.SignalChartViewModel(peripheral: peripheral)
        )
        log.debug(#function)
    }
    
    deinit {
        log.debug(#function)
    }
    
    func onConnect() async {
        log.debug(#function)
        // TODO: Fix CoreBluetooth API MISUSE
//            env.signalChartViewModel.onConnect()
        
        try? await discoverServices()
    }
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
        env.signalChartViewModel.onDisconnect()
    }
}

// MARK: Private Methods
private extension ViewModel {
    
    private func discoverServices() async throws {
        // Discover Services
        let services: [Service] = [.batteryService, .deviceInformation]
        let cbServices = try await peripheral
            .discoverServices(serviceUUIDs: services.map(\.uuid))
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        
    }
}

private extension ViewModel {
    enum Err: Error {
        case unknown
    }
}

// MARK: - Environment

extension PeripheralInspectorViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate(set) var criticalError: CriticalError?
        @Published var alertError: Error?
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
        
        let deviceId: UUID
        
        let signalChartViewModel: SignalChartScreen.SignalChartViewModel
        
        fileprivate(set) var disconnect: () -> ()
        
        private let l = NordicLog(category: "PeripheralInspector.Env")
        
        init(
            deviceId: UUID,
            criticalError: CriticalError? = nil,
            alertError: Error? = nil,
            internalAlertError: AlertError? = nil,
            signalChartViewModel: SignalChartScreen.SignalChartViewModel,
            disconnect: @escaping () -> () = { }
        ) {
            self.deviceId = deviceId
            self.criticalError = criticalError
            self.alertError = alertError
            self.internalAlertError = internalAlertError
            self.signalChartViewModel = signalChartViewModel
            self.disconnect = disconnect
            
            l.debug(#function)
        }
        
        deinit {
            l.debug(#function)
        }
    }
}

// MARK: - Errors
extension PeripheralInspectorViewModel.Environment {
    enum CriticalError: LocalizedError {
        case unknown
    }

    enum AlertError: LocalizedError {
        case unknown
    }
}

extension PeripheralInspectorViewModel.Environment.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}

extension PeripheralInspectorViewModel.Environment.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}
