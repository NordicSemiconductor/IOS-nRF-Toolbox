//
//  HealthThermometerViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI

private typealias ViewModel = HealthThermometerScreen.VM

extension HealthThermometerScreen {
    typealias VM = HealthThermometerViewModel

    @MainActor 
    class HealthThermometerViewModel: ObservableObject {
        let env = Environment()

        private var cancellables = Set<AnyCancellable>()
    }
}

// MARK: Private Methods
private extension HealthThermometerScreen.VM {

}

private extension HealthThermometerScreen.VM {
    enum Err: Error {
        case unknown
    }
}

// MARK: - Environment
extension HealthThermometerScreen.VM {
    @MainActor
    class Environment: ObservableObject {
        @Published var currentTemperature: Measurement<UnitTemperature>?
        
        @Published fileprivate (set) var criticalError: CriticalError?
        @Published var alertError: Error?
        
        init(
            currentTemperature: Measurement<UnitTemperature>? = nil,
            alertError: Error? = nil
        ) {
            self.criticalError = criticalError
            self.alertError = alertError
            self.currentTemperature = currentTemperature
        }
        
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
    }
}

// MARK: - Errors
extension HealthThermometerScreen.VM.Environment {
    enum CriticalError: LocalizedError {
        case unknown
    }

    enum AlertError: LocalizedError {
        case unknown
    }
}

extension HealthThermometerScreen.VM.Environment.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}

extension HealthThermometerScreen.VM.Environment.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        }
    }
}
