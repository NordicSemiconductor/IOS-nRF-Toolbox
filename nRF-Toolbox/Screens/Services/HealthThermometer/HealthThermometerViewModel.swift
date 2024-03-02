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
    typealias Env = Environment
    
    struct TemperatureRecord {
        let temperature: Measurement<UnitTemperature>
        let date: Date
    }
    
    @MainActor
    class Environment: ObservableObject {
        var currentTemperature: Measurement<UnitTemperature>? {
            records.last?.temperature
        }
        
        @Published var records: [TemperatureRecord] {
            didSet {
                min = (records.min(by: { $0.temperature < $1.temperature })?.temperature.value ?? 35 ) - 2
                max = (records.max(by: { $0.temperature > $1.temperature })?.temperature.value ?? 42 ) + 2
            }
        }
        
        @Published fileprivate (set) var criticalError: CriticalError?
        @Published var alertError: Error?
        
        @Published fileprivate (set) var min: Double = 32
        @Published fileprivate (set) var max: Double = 45
        
        init(
            records: [TemperatureRecord] = [],
            alertError: Error? = nil
        ) {
            self.criticalError = nil
            self.alertError = alertError
            self.records = records
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
