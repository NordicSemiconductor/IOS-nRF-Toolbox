//
//  ThroughputViewModel.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 27/1/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetoothMock
import CoreBluetoothMock_Collection
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - ThroughputViewModel

final class ThroughputViewModel: ObservableObject {
    
    // MARK: Published
    
    @Published fileprivate(set) var inProgress: Bool
    @Published fileprivate(set) var readData: ThroughputData?
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var throughputTask: Task<(), Never>!
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "ThroughputViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(_ peripheral: Peripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service
        self.inProgress = false
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
    
    // MARK: toggle
    
    func toggle() {
        inProgress.toggle()
        switch inProgress {
        case true:
            do {
                try start()
            }
            catch let error {
                log.error("Error \(error.localizedDescription)")
                inProgress = false
            }
        case false:
            throughputTask?.cancel()
            throughputTask = nil
        }
    }
    
    // MARK: start()
    
    func start() throws {
        log.debug(#function)
        Task { @MainActor [unowned self] in
            let characteristics: [Characteristic] = [.throughputCharacteristic]
            let cbCharacteristics = try await peripheral
                .discoverCharacteristics(characteristics.map(\.uuid), for: service)
                .timeout(1, scheduler: DispatchQueue.main)
                .firstValue
            
            // Check if `throughput` characteristic was discovered
            guard let cbThroughput = cbCharacteristics.first,
                  cbThroughput.uuid == Characteristic.throughputCharacteristic.uuid else {
                return
            }
            
            await reset()
            throughputTask = Task.detached(priority: .userInitiated) { [peripheral, log] in
                while !Task.isCancelled {
                    do {
                        _ = try await peripheral.isReadyToSendWriteWithoutResponse().firstValue
                    } catch {
                        log.error(error.localizedDescription)
                        return
                    }
                    
                    let equalsSign = Data(repeating: 61, count: peripheral.peripheral.maximumWriteValueLength(for: .withoutResponse))
                    peripheral.writeValueWithoutResponse(equalsSign, for: cbThroughput)
                }
                log.debug("Finished Throughput Task")
            }
        }
    }
    
    // MARK: read()
    
    func read() {
        Task { @MainActor [unowned self] in
            do {
                let characteristics: [Characteristic] = [.throughputCharacteristic]
                let cbCharacteristics = try await peripheral
                    .discoverCharacteristics(characteristics.map(\.uuid), for: service)
                    .timeout(1, scheduler: DispatchQueue.main)
                    .firstValue
                
                // Check if `throughput` characteristic was discovered
                guard let cbThroughput = cbCharacteristics.first,
                      cbThroughput.uuid == Characteristic.throughputCharacteristic.uuid else {
                    return
                }
                
                guard let result = try await peripheral.readValue(for: cbThroughput).firstValue else {
                    return
                }
                readData = ThroughputData(result)
            } catch {
                log.error(error.localizedDescription)
            }
        }
    }
    
    // MARK: reset()
    
    func reset() async {
        log.debug(#function)
        
        let characteristics: [Characteristic] = [.throughputCharacteristic]
        let cbCharacteristics = try? await peripheral
            .discoverCharacteristics(characteristics.map(\.uuid), for: service)
            .timeout(1, scheduler: DispatchQueue.main)
            .firstValue
        
        // Check if `throughput` characteristic was discovered
        guard let cbThroughput = cbCharacteristics?.first,
              cbThroughput.uuid == Characteristic.throughputCharacteristic.uuid else {
            return
        }
        
        let resetByte = Data(repeating: 0, count: 1)
        peripheral.writeValueWithoutResponse(resetByte, for: cbThroughput)
        
        // Ensure reset byte is flushed.
        _ = try? await peripheral.isReadyToSendWriteWithoutResponse().firstValue
    }
}

// MARK: - SupportedServiceViewModel

extension ThroughputViewModel: SupportedServiceViewModel {
    
    func onConnect() async {
        // No-op.
    }
    
    func onDisconnect() {
        cancellables.removeAll()
    }
}
