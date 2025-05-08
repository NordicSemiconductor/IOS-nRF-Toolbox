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
    
    @Published private(set) var macros: [UARTMacro] = [.none]
    @Published var selectedMacro = UARTMacro.none
    
    // MARK: init
    
    init(peripheral: Peripheral, uartService: CBService) {
        self.peripheral = peripheral
        self.service = uartService
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
        if let savedMacros = Self.read() {
            self.macros = savedMacros
        }
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
            let uartMessage = UARTMessage(text: newMessage, source: .user,
                                          previousMessage: messages.last)
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
                let cleanString = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                return UARTMessage(text: cleanString, source: .other, previousMessage: nil)
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [log] _ in
                log.debug("Completion")
            }, receiveValue: { incoming in
                let newMessage = UARTMessage(text: incoming.text, source: incoming.source, previousMessage: self.messages.last)
                self.messages.append(newMessage)
            })
            .store(in: &cancellables)
    }
    
    @MainActor
    func clearReceivedMessages() {
        messages = []
    }
    
    @MainActor
    func newMacro(named: String) {
        let newMacro = UARTMacro(named)
        macros.append(newMacro)
        selectedMacro = newMacro
        let copy = macros
        Task.detached {
            Self.writeBack(macros: copy)
        }
    }
    
    @MainActor
    func deleteSelectedMacro() {
        guard selectedMacro != .none else { return }
        if let i = macros.firstIndex(of: selectedMacro) {
            macros.remove(at: i)
            selectedMacro = macros.first ?? .none
        }
    }
}

// MARK: - Storage

fileprivate extension UARTViewModel {
    
    static let fileManager = FileManager.default
    
    private static func read() -> [UARTMacro]? {
        let fileUrl = try? self.fileUrl(for: "macros")
        guard let fileUrl, let readData = try? Data(contentsOf: fileUrl) else { return nil }
        let decodedData = try? JSONDecoder().decode([UARTMacro].self, from: readData)
        return decodedData
    }
    
    private static func writeBack(macros: [UARTMacro]) {
        let fileUrl = try? self.fileUrl(for: "macros")
        let jsonData = try? JSONEncoder().encode(macros)
        
        guard let fileUrl, let jsonData else { return }
        try? jsonData.write(to: fileUrl)
    }
    
    private static func macrosDir() throws -> URL {
        return try Self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("macros")
    }
    
    private static func fileUrl(for name: String) throws -> URL {
        let documentDirectory = try macrosDir()
        if !Self.fileManager.fileExists(atPath: documentDirectory.path) {
            try Self.fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return documentDirectory.appendingPathComponent(name).appendingPathExtension("json")
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
