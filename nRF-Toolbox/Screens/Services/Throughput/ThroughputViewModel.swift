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
    
    // MARK: Mode
    
    enum Mode: Hashable, CustomStringConvertible, CaseIterable {
        case limitedSize
        case limitedTime
        
        var description: String {
            switch self {
            case .limitedSize:
                return "Data Limit"
            case .limitedTime:
                return "Time Limit"
            }
        }
    }
    
    // MARK: Published
    
    @Published fileprivate(set) var inProgress: Bool
    @Published fileprivate(set) var readData: ThroughputData
    @Published fileprivate(set) var testProgress: Double
    @Published var mtu: Int
    @Published var testSize: Measurement<UnitInformationStorage>
    @Published var testDuration: Measurement<UnitDuration>
    @Published var testTimeLimit: Measurement<UnitDuration>
    @Published var testMode: Mode
    
    // MARK: Private Properties
    
    private let service: CBService
    private let peripheral: Peripheral
    
    private var throughputTask: Task<(), Never>!
    private var startTime: DispatchTime!
    private var endTime: DispatchTime!
    private var progressSubject: PassthroughSubject<Double, Never>
    private var cancellables: Set<AnyCancellable>
    private let log = NordicLog(category: "ThroughputViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(_ peripheral: Peripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service
        self.mtu = peripheral.MTU()
        self.testSize = Measurement(value: 100, unit: .kilobytes)
        self.testDuration = Measurement(value: .zero, unit: .seconds)
        self.testTimeLimit = Measurement(value: 20.0, unit: .seconds)
        self.testMode = .allCases[0]
        self.inProgress = false
        self.testProgress = .zero
        self.readData = ThroughputData(Data())
        self.progressSubject = PassthroughSubject<Double, Never>()
        self.cancellables = Set<AnyCancellable>()
        log.debug(#function)
        
        progressSubject
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [unowned self] in
                let newValue = $0
                withAnimation {
                    testProgress = newValue
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK:
    
    var isTimeLimited: Bool {
        switch testMode {
        case .limitedSize:
            return false
        case .limitedTime:
            return true
        }
    }
    
    // MARK: runTest
    
    func runTest() {
        Task { @MainActor [unowned self] in
            inProgress.toggle()
            switch inProgress {
            case true:
                do {
                    testProgress = .zero
                    await reset()
                    mtu = min(max(mtu, 1), peripheral.MTU())
                    log.info("MTU set to \(mtu) bytes.")
                    var testSize = Measurement<UnitInformationStorage>(value: 19, unit: .megabytes)
                    switch testMode {
                    case .limitedSize:
                        testSize = self.testSize
                    case .limitedTime:
                        let timeLimit = Int(testTimeLimit.value)
                        Task { [unowned self] in
                            var currentTime = 0
                            while currentTime < timeLimit {
                                try await Task.sleep(for: .seconds(1))
                                currentTime += 1
                                progressSubject.send(Double(currentTime) / Double(timeLimit) * 100)
                                guard let throughputTask, !throughputTask.isCancelled else { break }
                            }
                            
                            throughputTask?.cancel()
                            await testFinished()
                        }
                    }
                    
                    startTime = .now()
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
        
        throughputTask = Task.detached(priority: .userInitiated) { [peripheral, log, isTimeLimited, progressSubject] in
            log.debug("Throughput Task Started")
            let testSizeInBytes = Int(size.converted(to: .bytes).value)
            var bytesSent: Int = 0
            while !Task.isCancelled {
                guard isTimeLimited || bytesSent <= testSizeInBytes else { break }
                do {
                    _ = try await peripheral.isReadyToSendWriteWithoutResponse().firstValue
                } catch {
                    log.error(error.localizedDescription)
                    return
                }
                
                let equalsSign = Data(repeating: 61, count: mtu)
                peripheral.writeValueWithoutResponse(equalsSign, for: cbThroughput)
                bytesSent += equalsSign.count
                if !isTimeLimited {
                    progressSubject.send(min(Double(bytesSent) / Double(testSizeInBytes) * 100, 100.0))
                }
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
        endTime = .now()
        readData = await read()
        let elapsedNanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let measurement = Measurement<UnitDuration>(value: Double(elapsedNanoseconds), unit: .nanoseconds)
        testDuration = measurement.converted(to: .seconds)
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
