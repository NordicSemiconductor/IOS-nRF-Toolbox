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
import iOS_Common_Libraries

// MARK: HeartRateMeasurementCharacteristic

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

private typealias ViewModel = DeviceScreen.HeartRateViewModel

// MARK: - HeartRateViewModel

extension DeviceScreen {
    
    @MainActor
    class HeartRateViewModel: ObservableObject {
        
        private let peripheral: Peripheral
        private let heartRateService: CBService
        private var hrMeasurement: CBCharacteristic!
        private var cancelable = Set<AnyCancellable>()
        
        private let log = NordicLog(category: "HeartRateViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
        
        @Published fileprivate(set) var data: [HeartRateMeasurementCharacteristic] = []
        @Published var scrolPosition: Date = Date()
        
        @Published fileprivate(set) var criticalError: CriticalError?
        @Published var alertError: Error?
        
        let visibleDomain = 60
        let capacity = 360
        
        @Published fileprivate(set) var lowest: Int = 40
        @Published fileprivate(set) var highest: Int = 200
        
        fileprivate var internalAlertError: AlertError? {
            didSet {
                alertError = internalAlertError
            }
        }
        
        init(peripheral: Peripheral, heartRateService: CBService) {
            self.peripheral = peripheral
            self.data = []
            self.criticalError = nil
            self.alertError = nil
            
            assert(heartRateService.uuid == Service.heartRate.uuid)
            
            self.heartRateService = heartRateService
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
        
        func prepare() async {
            do {
                try await discoverCharacteristics()
            } catch {
                criticalError = .noMandatoryCharacteristic
            }
        }
    }
}

// MARK: - SupportedServiceViewModel

extension DeviceScreen.HeartRateViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        await prepare()
    }
    
    func onDisconnect() {
        cancelable.removeAll()
    }
}

// MARK: - Private

private extension ViewModel {
    
    // MARK: discoverCharacteristics()
    
    func discoverCharacteristics() async throws {
        let hrCharacteristics: [Characteristic] = [.heartRateMeasurement]
        
        let heartRateCharacteristic = try await peripheral.discoverCharacteristics(hrCharacteristics.map(\.uuid), for: heartRateService)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        for characteristic in heartRateCharacteristic where characteristic.uuid == Characteristic.heartRateMeasurement.uuid {
            try await enableHRMeasurement(characteristic)
        }
    }
    
    // MARK: enableHRMeasurement()
    
    func enableHRMeasurement(_ characteristic: CBCharacteristic) async throws {
        peripheral.listenValues(for: characteristic)
            .compactMap { data in
                return try? HeartRateMeasurementCharacteristic(with: data, date: Date())
            }
            .sink { completion in
                if case .failure = completion {
                    self.internalAlertError = .measurement
                }
            } receiveValue: { [unowned self] newValue in
                if newValue.date.timeIntervalSince1970 - scrolPosition.timeIntervalSince1970 < CGFloat(visibleDomain + 5) || data.isEmpty {
                    scrolPosition = Date()
                }

                data.append(newValue)
                
                if data.count > capacity {
                    data.removeFirst()
                }
                
                let min = (data.min { $0.heartRate < $1.heartRate }?.heartRate ?? 40)
                let max  = (data.max { $0.heartRate < $1.heartRate }?.heartRate ?? 140)
                
                lowest = min - 5
                highest = max + 5
            }
            .store(in: &cancelable)
        
        _ = try await peripheral.setNotifyValue(true, for: characteristic).firstValue
    }
}

private extension ViewModel {
    enum Err: Error {
        
    }
}

// MARK: - Errors

extension DeviceScreen.HeartRateViewModel {
    
    enum CriticalError: LocalizedError {
        case unknown
        case noMandatoryCharacteristic
    }

    enum AlertError: LocalizedError {
        case unknown
        case measurement
    }
}

extension DeviceScreen.HeartRateViewModel.CriticalError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .noMandatoryCharacteristic:
            return "No mandatory characteristic"
        }
    }
}

extension DeviceScreen.HeartRateViewModel.AlertError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .measurement:
            return "Error occured while reading measurement"
        }
    }
}
