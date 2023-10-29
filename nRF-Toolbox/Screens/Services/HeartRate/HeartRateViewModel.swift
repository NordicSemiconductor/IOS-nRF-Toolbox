//
//  HeartRateViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database

// MARK: Model

struct HeartRateMeasurementCharacteristic {
    let heartRate: Int
    let date: Date
    
    init(heartRate: Int, date: Date) {
        self.heartRate = heartRate
        self.date = date
    }
    
    init(with data: Data, date: Date) throws {
        self.date = date

        let flags: UInt8 = try data.read()
        if flags & 0x01 == 0 {
            heartRate = Int(try data.read(fromOffset: 1) as UInt8)
        } else {
            heartRate = Int(try data.read(fromOffset: 1) as UInt16)
        }
    }
}


private typealias ViewModel = HeartRateScreen.ViewModel

extension HeartRateScreen {
    @MainActor 
    class ViewModel: ObservableObject {
        let env = Environment()
        
        private let peripheral: Peripheral
        private let hrService: CBService
        
        private var hrMeasurement: CBCharacteristic!
        
        private var cancelable = Set<AnyCancellable>()
        
        init(peripheral: Peripheral, hrService: CBService) {
            self.peripheral = peripheral
            
            assert(hrService.uuid == Service.heartRate.uuid)
            
            self.hrService = hrService
        }
        
        func prepare() async {
            do {
                try await discoverCharacteristics()
            } catch {
                env.criticalError = .noMandatoryCharacteristic
            }
        }
    }
}

// MARK: Private Methods
private extension ViewModel {
    func discoverCharacteristics() async throws {
        let hrCharacteristics: [Characteristic] = [.heartRateMeasurement]
        
        let hrCbCh = try await peripheral.discoverCharacteristics(hrCharacteristics.map(\.uuid), for: hrService)
            .timeout(1, scheduler: DispatchQueue.main)
            .value
        
        for ch in hrCbCh {
            if ch.uuid == Characteristic.heartRateMeasurement.uuid {
                try await enableHRMeasurement(ch)
            }
        }
    }
    
    func enableHRMeasurement(_ characteristic: CBCharacteristic) async throws {
        peripheral.listenValues(for: characteristic)
            .compactMap { data in
                return try? HeartRateMeasurementCharacteristic(with: data, date: Date())
            }
            .sink { completion in
                if case .failure = completion {
                    self.env.internalAlertError = .measurement
                }
            } receiveValue: { [unowned self] v in
                if v.date.timeIntervalSince1970 - env.scrolPosition.timeIntervalSince1970 < CGFloat(env.visibleDomain + 5) || env.data.isEmpty {
                    env.scrolPosition = Date()
                }

                env.data.append(v)
                
                if env.data.count > env.capacity {
                    env.data.removeFirst()
                }
                
                let min = (env.data.min { $0.heartRate < $1.heartRate }?.heartRate ?? 40)
                let max  = (env.data.max { $0.heartRate < $1.heartRate }?.heartRate ?? 140)
                
                env.lowest = min - 5
                env.highest = max + 5

            }
            .store(in: &cancelable)
        
        _ = try await peripheral.setNotifyValue(true, for: characteristic).value
    }
}



private extension ViewModel {
    enum Err: Error {
        
    }
}

// MARK: - Environment
extension HeartRateScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var data: [HeartRateMeasurementCharacteristic] = []
        @Published var scrolPosition: Date = Date()
        
        @Published fileprivate (set) var criticalError: CriticalError?
        @Published var alertError: Error?
        
        let visibleDomain = 120
        let capacity = 360
        
        @Published fileprivate (set) var lowest: Int = 40
        @Published fileprivate (set) var highest: Int = 200
        
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
        
        init(data: [HeartRateMeasurementCharacteristic] = [], criticalError: CriticalError? = nil, alertError: Error? = nil) {
            self.data = data
            self.criticalError = criticalError
            self.alertError = alertError
            
            assert(capacity >= visibleDomain)
        }
    }
}

// MARK: - Errors
extension HeartRateScreen.ViewModel.Environment {
    enum CriticalError: LocalizedError {
        case unknown
        case noMandatoryCharacteristic
    }

    enum AlertError: LocalizedError {
        case unknown
        case measurement
    }
}

extension HeartRateScreen.ViewModel.Environment.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .noMandatoryCharacteristic:
            return "No mandatory characteristic"
        }
    }
}

extension HeartRateScreen.ViewModel.Environment.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .measurement:
            return "Error occured while reading measurement"
        }
    }
}
