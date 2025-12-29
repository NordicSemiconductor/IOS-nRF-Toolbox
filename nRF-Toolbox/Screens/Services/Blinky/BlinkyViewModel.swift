//
//  BlinkyViewModel.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 5/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - BlinkyViewModel

final class BlinkyViewModel: SupportedServiceViewModel, ObservableObject {
    
    // MARK: Private Properties
    
    private let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "BlinkyViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published var isLedOn: Bool = false
    @Published private(set) var isButtonPressed: Bool = false
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    // MARK: init
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.cancellables = Set<AnyCancellable>()
        self.characteristics = characteristics
        log.debug(#function)
    }
    
    // MARK: description
    
    var description: String {
        "LED Button Service"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return BlinkyView()
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
    
    @MainActor
    private func initializeCharacteristics() async throws {
        log.debug(#function)
        
        let characteristics: [Characteristic] = [.nordicsemiBlinkyLedState, .nordicsemiBlinkyButtonState]
        let blinkyCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
            characteristics.contains { $0.uuid == cbChar.uuid }
        }
        
        guard let buttonCharacteristics = blinkyCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.nordicsemiBlinkyButtonState.uuid) else {
            throw ServiceError.noMandatoryCharacteristic
        }
        guard let ledCharacteristics = blinkyCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.nordicsemiBlinkyLedState.uuid) else {
            throw ServiceError.noMandatoryCharacteristic
        }
        
        if let initialValue = try await peripheral.readValue(for: buttonCharacteristics).firstValue {
            log.debug("peripheral.readValue(characteristic): \(initialValue.hexEncodedString(options: [.prepend0x, .twoByteSpacing]))")
            isButtonPressed = initialValue.littleEndianBytes(as: UInt8.self) > 0
        }
        
        listenToButtonPress(buttonCharacteristics)
        let isNotifyEnabled = try await peripheral.setNotifyValue(true, for: buttonCharacteristics).firstValue
        guard isNotifyEnabled else { throw ServiceError.notificationsNotEnabled }
        log.debug("peripheral.setNotifyValue(true, for: .nordicsemiBlinkyButtonState): \(isNotifyEnabled)")
        
        $isLedOn
            .map { [log] newValue in
                log.debug("Changed to \(newValue)")
                return Data(repeating: newValue ? 1 : 0, count: 1)
            }
            .sink { [log, peripheral] data in
                Task {
                    log.debug("Writing \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing]))")
                    _ = try? await peripheral.writeValueWithResponse(data, for: ledCharacteristics).firstValue
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: onDisconnect()
    
    func onDisconnect() {
        log.debug(#function)
        cancellables.removeAll()
    }
    
    // MARK: listenToButtonPress()
    
    func listenToButtonPress(_ characteristic: CBCharacteristic) {
        peripheral.listenValues(for: characteristic)
            .map { [weak self] data in
                self?.log.debug("Received \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing]))")
                return data.littleEndianBytes(as: UInt8.self) > 0
            }
            .sink(to: \.isButtonPressed, in: self, assigningInCaseOfError: false)
            .store(in: &cancellables)
    }
}
