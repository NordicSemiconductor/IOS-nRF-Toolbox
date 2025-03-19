//
//  BatteryViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 4/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock_Collection

// MARK: - BatteryViewModel

final class BatteryViewModel: ObservableObject {
    
    // MARK: Properties
    
    @Published fileprivate(set) var batteryLevelData: [ChartTimeData<Battery.Level>]
    @Published fileprivate(set) var currentBatteryLevel: UInt?
    @Published fileprivate(set) var batteryLevelAvailable: Bool
    
    private let service: CBService
    private let peripheral: Peripheral
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "BatteryViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    private static let batteryLevelDataLength = 120
    
    // MARK: init
    
    init(peripheral: Peripheral, batteryService: CBService) {
        self.peripheral = peripheral
        self.service = batteryService
        self.cancellables = Set<AnyCancellable>()
        self.batteryLevelData = []
        self.currentBatteryLevel = nil
        self.batteryLevelAvailable = false
        log.debug(#function)
    }
    
    // startListening()
    
    @MainActor
    func startListening() async throws {
        log.debug(#function)
        let characteristics: [Characteristic] = [.batteryLevel]
        let cbCharacteristics = try await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        // Check if `batteryLevel` characteristic was discovered
        guard let cbBatteryLevel = cbCharacteristics.first, cbBatteryLevel.uuid == Characteristic.batteryLevel.uuid else {
            return
        }
        
        batteryLevelAvailable = true
        do {
            // try to enable notifications for
            if try await peripheral.setNotifyValue(true, for: cbBatteryLevel).timeout(1, scheduler: DispatchQueue.main).firstValue {
                // in case of success - listen
                listen(for: cbBatteryLevel)
            } else {
                // otherwise - read
                try? await readBatteryLevelOnTimer(cbBatteryLevel)
            }
        } catch {
            try? await readBatteryLevelOnTimer(cbBatteryLevel)
        }
    }
    
    // MARK: listen(for:)
    
    private func listen(for batteryLevelCh: CBCharacteristic) {
        log.debug(#function)
        let publisher = peripheral.listenValues(for: batteryLevelCh)
            .eraseToAnyPublisher()
        
        handleBatteryPublisher(publisher)
    }
    
    // MARK: readBatteryLevelOnTimer()
    
    private func readBatteryLevelOnTimer(_ batteryLevelCh: CBCharacteristic, timeInterval: TimeInterval = 1) async throws {
        let publisher = Timer.publish(every: 60, on: .main, in: .default)
            .autoconnect()
            .flatMap { [unowned self] _ in
                self.peripheral.readValue(for: batteryLevelCh)
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()

        handleBatteryPublisher(publisher)
    }
    
    // MARK: handleBatteryPublisher()
    
    private func handleBatteryPublisher(_ publisher: AnyPublisher<Data, Error>) {
        publisher
            .map { Battery.Level(data: $0) }
            .map { ChartTimeData<Battery.Level>(value: $0) }
            .scan(Array<ChartTimeData<Battery.Level>>(), { result, lvl in
                var res = result
                res.append(lvl)
                if res.count > Self.batteryLevelDataLength {
                    res.removeFirst()
                }
                return res
            })
            .sink { completion in
                
            } receiveValue: { [unowned self] level in
                var lvlData = level
                while lvlData.count < Self.batteryLevelDataLength {
                    let date = (lvlData.last?.date).map { Date(timeInterval: 1, since: $0) } ?? Date()
                    lvlData.append(.init(value: 0, date: date))
                }
                
                currentBatteryLevel = level.last?.value.level
                batteryLevelData = lvlData
            }
            .store(in: &cancellables)
    }
}

// MARK: - SupportedServiceViewModel

extension BatteryViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        do {
            try await startListening()
        }
        catch {
            // TODO: Later, I guess.
            log.error(error.localizedDescription)
        }
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}
