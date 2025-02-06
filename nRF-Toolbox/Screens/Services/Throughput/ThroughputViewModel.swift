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
    @Published fileprivate(set) var readData: ThroughputData
    @Published var mtu: Int
    @Published var testSize: Measurement<UnitInformationStorage>
    
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
        self.mtu = peripheral.MTU()
        self.testSize = Measurement(value: 100, unit: .kilobytes)
        self.inProgress = false
        self.readData = ThroughputData(Data())
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
    }
    
    // MARK: runTest
    
    func runTest() {
        Task { @MainActor [unowned self] in
            inProgress.toggle()
            switch inProgress {
            case true:
                do {
                    await reset()
                    log.info("MTU set to \(mtu) bytes.")
                    try await start(testSize, using: mtu)
                }
                catch let error {
                    log.error("Error \(error.localizedDescription)")
                    inProgress = false
                }
            case false:
                throughputTask?.cancel()
                await testFinished()
            }
        }
    }
    
    // MARK: start()
    
    func start(_ size: Measurement<UnitInformationStorage>, using mtu: Int) async throws {
        log.debug(#function)
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
        
        throughputTask = Task.detached(priority: .userInitiated) { [peripheral, log] in
            log.debug("Throughput Task Started")
            let testSizeInBytes = Int(size.converted(to: .bytes).value)
            var bytesSent: Int = 0
            while !Task.isCancelled, bytesSent <= testSizeInBytes {
                do {
                    _ = try await peripheral.isReadyToSendWriteWithoutResponse().firstValue
                } catch {
                    log.error(error.localizedDescription)
                    return
                }
                
                let equalsSign = Data(repeating: 61, count: mtu)
                peripheral.writeValueWithoutResponse(equalsSign, for: cbThroughput)
                bytesSent += equalsSign.count
            }
            log.debug("Finished Throughput Task")
        }
        
        _ = await throughputTask.result
        let cancelledByUser = throughputTask.isCancelled
        throughputTask = nil
        guard !cancelledByUser else { return }
        await testFinished()
    }
    
    // MARK: read()
    
    func read() async -> ThroughputData {
        do {
            let characteristics: [Characteristic] = [.throughputCharacteristic]
            let cbCharacteristics = try await peripheral
                .discoverCharacteristics(characteristics.map(\.uuid), for: service)
                .timeout(1, scheduler: DispatchQueue.main)
                .firstValue
            
            // Check if `throughput` characteristic was discovered
            guard let cbThroughput = cbCharacteristics.first,
                  cbThroughput.uuid == Characteristic.throughputCharacteristic.uuid else {
                return ThroughputData(Data())
            }
            
            guard let result = try await peripheral.readValue(for: cbThroughput).firstValue else {
                return ThroughputData(Data())
            }
            log.debug("Successfully Read Data")
            return ThroughputData(result)
        } catch {
            log.error(error.localizedDescription)
        }
        return ThroughputData(Data())
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
        
        // Wait for reset byte.
        _ = try? await peripheral.isReadyToSendWriteWithoutResponse().firstValue
    }
    
    @MainActor
    func testFinished() async {
        readData = await read()
        inProgress = false
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
