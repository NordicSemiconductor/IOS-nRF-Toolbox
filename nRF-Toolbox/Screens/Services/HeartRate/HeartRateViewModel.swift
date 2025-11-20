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
final class HeartRateViewModel: @MainActor SupportedServiceViewModel, ObservableObject {
    
    private let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    private var hrMeasurement: CBCharacteristic!
    private var heartRateControlPoint: CBCharacteristic?
    private var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "HeartRateViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    @Published fileprivate(set) var data: [HeartRateValue] = []
    @Published fileprivate(set) var location: HeartRateMeasurement.SensorLocation?
    @Published fileprivate(set) var caloriesResetState = CaloriesResetState.unavailable
    @Published var scrollPosition = Date()
    @Published private(set) var minDate: Date = .distantPast
    @Published private(set) var maxDate: Date = .distantFuture
    
    @Published fileprivate(set) var criticalError: ServiceError?
    @Published var alertError: Error?
    
    let visibleDomain = 60
    let capacity = 360
    
    @Published fileprivate(set) var lowest: Int = 40
    @Published fileprivate(set) var highest: Int = 200
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    fileprivate var internalAlertError: ServiceWarning? {
        didSet {
            alertError = internalAlertError
        }
    }
    
    // MARK: init
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.data = []
        self.criticalError = nil
        self.alertError = nil
        self.characteristics = characteristics
        self.data.reserveCapacity(capacity)
        log.debug(#function)
        
        $data.sink { records in
            let values = records.map { $0.date }

            self.minDate = (values.min() ?? .distantPast).addingTimeInterval(-5)
            self.maxDate = (values.max() ?? .distantFuture).addingTimeInterval(5)
        }.store(in: &cancellables)
    }
    
    // MARK: deinit
    
    deinit {
        log.debug(#function)
    }
    
    // MARK: description
    
    var description: String {
        "Heart Monitor"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return HeartRateView()
            .environmentObject(self)
    }
    
    // MARK: onConnect()
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        do {
            try await initializeCharacteristics()
        } catch {
            log.error("Error \(error.localizedDescription)")
            handleError(error)
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
    
    // MARK: initializeCharacteristics()
    
    @MainActor
    func initializeCharacteristics() async throws {
        log.debug(#function)
        let hrCharacteristics: [Characteristic] = [.heartRateMeasurement, .bodySensorLocation, .heartRateControlPoint]
        
        let heartRateCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
            hrCharacteristics.contains { $0.uuid == cbChar.uuid }
        }
        
        hrMeasurement = heartRateCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.heartRateMeasurement.uuid)
        guard hrMeasurement != nil else {
            throw ServiceError.noMandatoryCharacteristic
        }
        
        try await notifyHRMeasurement(true)
        // in case of success - listen
        listenTo(hrMeasurement)
        
        guard let bodySensorCharacteristic = heartRateCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.bodySensorLocation.uuid) else { return }
        
        log.debug("Found Body Sensor Characteristic")
        location = try? await peripheral.readValue(for: bodySensorCharacteristic).tryMap { data in
            guard let data, data.canRead(UInt8.self, atOffset: 0) else {
                throw ServiceError.unknown
            }
            
            self.log.debug("Received location data: \(data.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
            
            return HeartRateMeasurement.SensorLocation(rawValue: RegisterValue(data[0]))
        }
        .timeout(.seconds(1), scheduler: DispatchQueue.main, customError: {
            ServiceError.unknown
        })
        .firstValue

        log.debug("Body Sensor Location: \(location.nilDescription)")
        
        heartRateControlPoint = heartRateCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.heartRateControlPoint.uuid)
        if heartRateControlPoint != nil {
            log.debug("Found Heart Rate Control Point Characteristic")
            caloriesResetState = .available
        }
    }
    
    // MARK: listenTo()
    
    func listenTo(_ characteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: characteristic)
            .compactMap { data in
                self.log.debug("Received measurement data: \(data.hexEncodedString(options: [.upperCase, .twoByteSpacing]))")
                return try? HeartRateValue(with: data)
            }
            .sink { completion in
                if case .failure = completion {
                    self.internalAlertError = ServiceWarning.measurement
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
    @MainActor
    func notifyHRMeasurement(_ enable: Bool) async throws {
        guard let hrMeasurement else { return }
        log.debug(#function)
        do {
            let result = try await peripheral.setNotifyValue(enable, for: hrMeasurement).firstValue
            log.debug("Enabled HR Measurement Characteristic: \(result)")
        } catch {
            log.error(error.localizedDescription)
            handleError(error)
        }
    }
}

// MARK: - Actions

extension HeartRateViewModel {
    
    @MainActor
    func resetMeasurement() {
        Task {
            if let heartRateControlPoint {
                log.debug("Reset energy counter - start")
                do {
                    self.errors.value.warning = nil
                    caloriesResetState = .inProgress
                    let command: [UInt8] = [0x01]  // Reset calories counter
                    let data = Data(command)
                    try await peripheral.writeValueWithResponse(data, for: heartRateControlPoint)
                        .firstValue
                    caloriesResetState = .available
                    log.debug("Reset energy counter - end")
                } catch {
                    caloriesResetState = .available
                    self.errors.value.warning = ServiceWarning.unknown
                    log.debug("Reset energy counter - error: \(error)")
                }
            } else {
                log.error("heartRateControlPoint is nil. Cannot reset measurement.")
            }
        }
    }
    
    func clearControlPointError() {
        caloriesResetState = .available
    }
}
