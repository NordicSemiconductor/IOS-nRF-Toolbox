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
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - UARTViewModel

final class UARTViewModel: SupportedServiceViewModel, ObservableObject {
    
    // MARK: Private Properties
    
    private let peripheral: Peripheral
    private let characteristics: [CBCharacteristic]
    private var uartRX: CBCharacteristic!
    private var uartTX: CBCharacteristic!
    
    private let fileManager = UARTFileManager()
    private let parser = UARTPresetsXmlParser()
    
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "UARTViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: Published
    
    @Published private(set) var messages: [UARTMessage] = []
    @Published var newMessage: String = ""
    
    @Published private(set) var presets: [UARTPresets] = [.none]
    @Published var selectedPresets = UARTPresets.none
    @Published var showEditPresetsSheet = false
    @Published var editCommandIndex: Int = 0
    @Published var showEditPresetSheet: Bool = false
    
    var selectedPresetsXml: String {
        let result = (try? parser.toXml(selectedPresets)) ?? "" //TODO: Improve to calculate only once when needed.
        log.debug("AAATESTAAA - \(result)")
        return result
    }
    
    var errors: CurrentValueSubject<ErrorsHolder, Never> = CurrentValueSubject<ErrorsHolder, Never>(ErrorsHolder())
    
    // MARK: init
    
    init(peripheral: Peripheral, characteristics: [CBCharacteristic]) {
        self.peripheral = peripheral
        self.characteristics = characteristics
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
        if let savedPresets = Self.read() {
            self.presets = savedPresets
            if self.presets.count >= 2 {
                self.selectedPresets = savedPresets[1]
            }
        }
    }
    
    // MARK: description
    
    var description: String {
        "UART"
    }
    
    // MARK: attachedView
    
    var attachedView: any View {
        return UARTView()
            .environmentObject(self)
    }
    
    // MARK: onConnect()
    
    @MainActor
    func onConnect() async {
        log.debug(#function)
        let characteristics: [Characteristic] = [
            .nordicsemiUartRx, .nordicsemiUartTx
        ]
        let cbCharacteristics: [CBCharacteristic] = self.characteristics.filter { cbChar in
            characteristics.contains { $0.uuid == cbChar.uuid }
        }
        
        uartRX = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.nordicsemiUartRx.uuid)
        uartTX = cbCharacteristics.first(where: \.uuid, isEqualsTo: Characteristic.nordicsemiUartTx.uuid)
        
        guard let uartTX else { return }
        do {
            let txEnable = try await peripheral.setNotifyValue(true, for: uartTX).firstValue
            log.debug("\(#function) tx.setNotifyValue(true): \(txEnable)")
            listenToIncomingMessages(uartTX)
        } catch {
            log.debug("Error when enabling UART listening: \(error.localizedDescription)")
            onDisconnect()
        }
    }
    
    // MARK: onDisconnect()
    
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
    func send(_ data: Data) async {
        guard let uartRX else { return }
        log.debug(#function)
        
        do {
            if let dataAsString = String(data: data, encoding: .utf8) {
                let cleanText = dataAsString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                let uartMessage = UARTMessage(text: cleanText, source: .user, previousMessage: messages.last)
                messages.append(uartMessage)
            } else {
                let rawBytes = "\(data.hexEncodedString(options: [.prepend0x, .twoByteSpacing, .upperCase]))"
                let uartMessage = UARTMessage(text: rawBytes, source: .user, previousMessage: messages.last)
                messages.append(uartMessage)
            }
            
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
    func newPresets(named: String) {
        let newPresets = UARTPresets(named)
        presets.append(newPresets)
        selectedPresets = newPresets
        savePresets()
    }
    
    @MainActor
    func runCommand(_ command: UARTPreset) {
        guard let data = command.data else { return }
        Task {
            await send(data)
        }
    }
    
    @MainActor
    func updateSelectedPresetsName(_ name: String) {
        guard selectedPresets != .none, let i = presets.firstIndex(of: selectedPresets) else { return }
        let commands = selectedPresets.commands
        let updatedPresets = UARTPresets(name, commands: commands)
        presets[i] = updatedPresets
        selectedPresets = updatedPresets
        savePresets()
    }
    
    @MainActor
    func updateSelectedPresetCommand(_ command: UARTPreset) {
        guard selectedPresets != .none, let i = presets.firstIndex(of: selectedPresets) else { return }
        var updatedCommands = selectedPresets.commands
        updatedCommands[command.id] = command
        let updatedPresets = UARTPresets(selectedPresets.name, commands: updatedCommands)
        presets[i] = updatedPresets
        selectedPresets = updatedPresets
        savePresets()
    }
    
    @MainActor
    func deleteSelectedPresets() {
        guard selectedPresets != .none else { return }
        if let i = presets.firstIndex(of: selectedPresets) {
            presets.remove(at: i)
            selectedPresets = presets.first ?? .none
        }
        savePresets()
    }
    
    // MARK: Private
    
    func savePresets() {
        let copy = presets
        Task.detached {
            Self.writeBack(presets: copy)
        }
    }
    
    func loadPresets(_ data: Data) {

        if let presets = try? parser.fromXml(data) {
            self.presets.append(presets)
            selectedPresets = presets
        }
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
