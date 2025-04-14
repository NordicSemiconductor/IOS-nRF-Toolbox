//
//  UARTViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

// MARK: - UARTViewModel

final class UARTViewModel: ObservableObject {
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    private var uartRX: CBCharacteristic!
    private var uartTX: CBCharacteristic!
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "UARTViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var messages: [UARTMessage] = []
    @Published var newMessage: String = ""
    
    // MARK: init
    
    init(peripheral: Peripheral, uartService: CBService) {
        self.peripheral = peripheral
        self.service = uartService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
}

// MARK: - SupportedServiceViewModel

extension UARTViewModel: SupportedServiceViewModel {
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .nordicsemiUartRx, .nordicsemiUartTx
        ]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        uartRX = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.nordicsemiUartRx.uuid)
        uartTX = cbCharacteristics?.first(where: \.uuid, isEqualsTo: Characteristic.nordicsemiUartTx.uuid)
        
        guard let uartTX else { return }
        do {
            let txEnable = try await peripheral.setNotifyValue(true, for: uartTX).firstValue
            log.debug("\(#function) tx.setNotifyValue(true): \(txEnable)")
            guard txEnable else {
                throw Err.unableToTurnOnNotifications
            }
            listenToIncomingMessages(uartTX)
        } catch {
            log.debug(error.localizedDescription)
            onDisconnect()
        }
    }
    
    func onDisconnect() {
        log.debug(#function)
        uartRX = nil
        uartTX = nil
        cancellables.removeAll()
    }
}

// MARK: API

extension UARTViewModel {
    
    @MainActor
    func sendMessage() async {
        guard let uartRX else { return }
        log.debug(#function)
        
        do {
            guard let data = newMessage.data(using: .utf8) else {
                throw Err.unableToEncodeString(newMessage)
            }
            let uartMessage = UARTMessage(text: newMessage, source: .user)
            messages.append(uartMessage)
            newMessage = ""
            
            try await peripheral.writeValueWithResponse(data, for: uartRX).firstValue
        } catch {
            log.debug("\(#function) Error: \(error.localizedDescription)")
        }
    }
    
    func listenToIncomingMessages(_ rxCharacteristic: CBCharacteristic) {
        log.debug(#function)
        peripheral.listenValues(for: rxCharacteristic)
            .compactMap { [log] data -> UARTMessage? in
                log.debug("Received Data \(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing])) (\(data.count) bytes)")
                guard let string = String(data: data, encoding: .utf8) else {
                    return nil
                }
                return UARTMessage(text: string, source: .other)
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                print("Completion")
            }, receiveValue: { newValue in
                self.messages.append(newValue)
            })
            .store(in: &cancellables)
    }
    
    @MainActor
    func clearReceivedMessages() {
        messages = []
    }
}

// MARK: - Error

extension UARTViewModel {
    
    enum Err: Error {
        case unableToTurnOnNotifications
        case unableToEncodeString(_ string: String)
    }
}

// MARK: - CBUUID

extension CBUUID {
    
    static let nordicsemiUART = CBUUID(service: .nordicsemiUART)
}
