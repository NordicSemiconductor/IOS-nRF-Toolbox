//
//  SignalChartViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import iOS_BLE_Library_Mock
import iOS_Common_Libraries
import Charts

// MARK: - SignalChartViewModel

@MainActor final class SignalChartViewModel {
    let environment = Environment()
    let peripheral: Peripheral
    
    private var cancellable = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "SignalChartViewModel",
                                subsystem: "com.nordicsemi.nrf-toolbox")
    
    // MARK: init
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
        log.debug(#function)
    }
    
    // MARK: deinit
    
    deinit {
        log.debug(#function)
    }
    
    // MARK: onConnect
    
    func onConnect() {
        log.debug(#function)
        
        // Run Timer every 1 second
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            // Run `readRSSI` on every timer's execution
            .flatMap { [unowned self] _ in
                self.peripheral.readRSSI()
                    .timeout(0.9, scheduler: DispatchQueue.main)
            }
            // Convert RSSI to SwiftUI's ChartData
            .map { Environment.ChartData(date: Date(), signal: $0.intValue) }
            .sink { completion in
                // TODO: Update handling
                switch completion {
                case .finished:
                    print("finished")
                case .failure:
                    print("failure")
                }
            } receiveValue: { [unowned self] newSignalItem in
                if newSignalItem.date.timeIntervalSince1970 - environment.scrollPosition.timeIntervalSince1970 < CGFloat(environment.visibleDomain + 5) || environment.chartData.isEmpty {
                    environment.scrollPosition = Date()
                }
                environment.chartData.append(newSignalItem)
                
                if environment.chartData.count > environment.capacity {
                    environment.chartData.removeFirst()
                }
                
                // Set chart's Y bounds
                let min = (environment.chartData.min { $0.signal < $1.signal }?.signal ?? -100)
                let max  = (environment.chartData.max { $0.signal < $1.signal }?.signal ?? -40)
                
                environment.lowest = min - 5
                environment.highest = max + 5
            }
            .store(in: &cancellable)
    }
    
    // MARK: onDisconnect
    
    func onDisconnect() {
        log.debug(#function)
        cancellable.removeAll()
    }
}

// MARK: - Environment

extension SignalChartViewModel {
    
    @MainActor final class Environment: ObservableObject {
        
        struct ChartData: Identifiable {
            let date: Date
            let signal: Int
            var id: TimeInterval { date.timeIntervalSince1970 }
        }
        
        @Published fileprivate(set) var chartData: [ChartData] = []
        @Published var scrollPosition = Date()
        
        let visibleDomain = 60
        let capacity = 180
        
        @Published fileprivate(set) var lowest: Int = -100
        @Published fileprivate(set) var highest: Int = -40
        
        private let log = NordicLog(category: "SignalChartViewModel.Environment",
                                    subsystem: "com.nordicsemi.nrf-toolbox")
        
        init(chartData: [ChartData] = []) {
            self.chartData = chartData
            assert(capacity >= visibleDomain)
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}
