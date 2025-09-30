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

final class BlinkyViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "BlinkyViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Properties
    
    @Published var isLedOn: Bool = false
    @Published private(set) var isButtonPressed: Bool = false
    
    // MARK: init
    
    init(peripheral: Peripheral, blinkyService: CBService) {
        self.peripheral = peripheral
        self.service = blinkyService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension BlinkyViewModel: SupportedServiceViewModel {
    
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
            let characteristics: [Characteristic] = [.nordicsemiBlinkyLedState, .nordicsemiBlinkyButtonState]
            let blinkyCharacteristics = try await peripheral.discoverCharacteristics(characteristics.map(\.uuid), for: service)
                    .timeout(1, scheduler: DispatchQueue.main)
                    .firstValue
            
            for characteristic in blinkyCharacteristics where characteristic.uuid == Characteristic.nordicsemiBlinkyButtonState.uuid {
                if let initialValue = try await peripheral.readValue(for: characteristic).firstValue {
                    log.debug("peripheral.readValue(characteristic): \(initialValue.hexEncodedString(options: [.prepend0x, .twoByteSpacing]))")
                    isButtonPressed = initialValue.littleEndianBytes(as: UInt8.self) > 0
                }
                
                let result = try await peripheral.setNotifyValue(true, for: characteristic).firstValue
                log.debug("peripheral.setNotifyValue(true, for: .nordicsemiBlinkyButtonState): \(result)")
                listenToButtonPress(characteristic)
            }
            
            for characteristic in blinkyCharacteristics where characteristic.uuid == Characteristic.nordicsemiBlinkyLedState.uuid {
                $isLedOn
                    .map { [log] newValue in
                        log.debug("Changed to \(newValue)")
                        return Data(repeating: newValue ? 1 : 0, count: 1)
                    }
                    .sink { [log, peripheral] data in
                        Task {
                            log.debug("Writing \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing]))")
                            _ = try? await peripheral.writeValueWithResponse(data, for: characteristic).firstValue
                        }
                    }
                    .store(in: &cancellables)
                break
            }
        }
        catch {
            log.error(error.localizedDescription)
        }
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
