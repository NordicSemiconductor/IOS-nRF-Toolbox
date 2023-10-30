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

private typealias ViewModel = PeripheralScreen.ViewModel

extension PeripheralScreen {
    @MainActor 
    class ViewModel: ObservableObject {
        let env: Environment

        private var cancellables = Set<AnyCancellable>()
        
        private let peripheral: Peripheral
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
            
            self.env = Environment(
                signalChartViewModel: SignalChartScreen.ViewModel(peripheral: peripheral),
                attributeTableViewModel: AttributeTableScreen.ViewModel(peripheral: peripheral)
            )
            
            env.signalChartViewModel.readSignal()
        }
    }
    
    #if DEBUG
    @MainActor
    class MockViewModel: ViewModel {
        static let shared = MockViewModel(peripheral: .preview)
    }
    #endif
}

// MARK: Private Methods
private extension ViewModel {

}

private extension ViewModel {
    enum Err: Error {
        case unknown
    }
}

// MARK: - Environment
extension PeripheralScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var criticalError: CriticalError?
        @Published var alertError: Error?
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
        
        let signalChartViewModel: SignalChartScreen.ViewModel
        let attributeTableViewModel: AttributeTableScreen.ViewModel
        
        fileprivate (set) var disconnect: () -> ()
        
        init(
            criticalError: CriticalError? = nil,
            alertError: Error? = nil,
            internalAlertError: AlertError? = nil,
            signalChartViewModel: SignalChartScreen.ViewModel = SignalChartScreen.MockViewModel.shared,
            attributeTableViewModel: AttributeTableScreen.ViewModel = AttributeTableScreen.MockViewModel.shared,
            disconnect: @escaping () -> () = { }
        ) {
            self.criticalError = criticalError
            self.alertError = alertError
            self.internalAlertError = internalAlertError
            self.signalChartViewModel = signalChartViewModel
            self.attributeTableViewModel = attributeTableViewModel
            self.disconnect = disconnect
        }
    }
}

// MARK: - Errors
extension PeripheralScreen.ViewModel.Environment {
    enum CriticalError: LocalizedError {
        case unknown
    }

    enum AlertError: LocalizedError {
        case unknown
    }
}

extension PeripheralScreen.ViewModel.Environment.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}

extension PeripheralScreen.ViewModel.Environment.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}
