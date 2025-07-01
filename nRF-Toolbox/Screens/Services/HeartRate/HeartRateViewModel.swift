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

// MARK: - HeartRateViewModel

@MainActor
final class HeartRateViewModel: ObservableObject {
    
    private let peripheral: Peripheral
    private let heartRateService: CBService
    private var hrMeasurement: CBCharacteristic!
    private var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "HeartRateViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    @Published fileprivate(set) var data: [HeartRateValue] = []
    @Published var scrollPosition = Date()
    
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
        self.data.reserveCapacity(capacity)
        log.debug(#function)
    }
    
    deinit {
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension HeartRateViewModel: SupportedServiceViewModel {
    
    // MARK: attachedView
    
    var attachedView: SupportedServiceAttachedView {
        return .heartRate(self)
    }
    
    // MARK: onConnect()
    
    func onConnect() async {
        log.debug(#function)
        do {
            try await discoverCharacteristics()
        } catch {
            criticalError = .noMandatoryCharacteristic
        }
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
//        await notifyHRMeasurement(false)
        cancellables.removeAll()
    }
}

// MARK: - Private

private extension HeartRateViewModel {
    
    // MARK: discoverCharacteristics()
    
    func discoverCharacteristics() async throws {
        log.debug(#function)
        let hrCharacteristics: [Characteristic] = [.heartRateMeasurement]
        let heartRateCharacteristic = try await peripheral.discoverCharacteristics(hrCharacteristics.map(\.uuid), for: heartRateService)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        for characteristic in heartRateCharacteristic where characteristic.uuid == Characteristic.heartRateMeasurement.uuid {
            hrMeasurement = characteristic
            do {
                try await notifyHRMeasurement(true)
                // in case of success - listen
                listenTo(hrMeasurement)
            } catch {
                log.error("Unable to Enable Notifications: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: listenTo()
    
    func listenTo(_ characteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: characteristic)
            .compactMap { data in
                try? HeartRateValue(with: data)
            }
            .sink { completion in
                if case .failure = completion {
                    self.internalAlertError = .measurement
                }
            } receiveValue: { [unowned self] newValue in
                let diff = newValue.date.timeIntervalSince1970 - scrollPosition.timeIntervalSince1970
                if diff < CGFloat(visibleDomain + 5) || data.isEmpty {
                    scrollPosition = .now
                }

                data.append(newValue)
                if data.count > capacity {
                    data.removeFirst()
                }
                
                let min = (data.min {
                    $0.measurement.heartRateValue < $1.measurement.heartRateValue
                }?.measurement.heartRateValue ?? 40)
                
                let max  = (data.max {
                    $0.measurement.heartRateValue < $1.measurement.heartRateValue
                }?.measurement.heartRateValue ?? 140)
                
                lowest = min - 5
                highest = max + 5
            }
            .store(in: &cancellables)
    }
    
    // MARK: notifyHRMeasurement()
    
    func notifyHRMeasurement(_ enable: Bool) async throws {
        guard let hrMeasurement else { return }
        log.debug(#function)
        do {
            let result = try await peripheral.setNotifyValue(enable, for: hrMeasurement).firstValue
            log.debug("Enabled HR Measurement Characteristic: \(result)")
        } catch {
            log.error(error.localizedDescription)
        }
    }
}

// MARK: - Errors

extension HeartRateViewModel {
    
    enum CriticalError: LocalizedError {
        case unknown
        case noMandatoryCharacteristic
        
        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error"
            case .noMandatoryCharacteristic:
                return "No mandatory characteristic"
            }
        }
    }

    enum AlertError: LocalizedError {
        case unknown
        case measurement
        
        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error"
            case .measurement:
                return "Error occured while reading measurement"
            }
        }
    }
}
