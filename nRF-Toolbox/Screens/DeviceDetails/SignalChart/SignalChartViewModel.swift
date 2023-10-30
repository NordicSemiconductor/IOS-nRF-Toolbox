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
import Charts

extension SignalChartScreen {
    @MainActor
    class ViewModel: ObservableObject {
        let environment = Environment()
        let peripheral: Peripheral
        
        private var cancelable = Set<AnyCancellable>()
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
        }
        
        public func readSignal() {
            Timer.publish(every: 1, on: .main, in: .default)
                .autoconnect()
                .flatMap { _ in
                    self.peripheral.readRSSI()
                        .timeout(0.9, scheduler: DispatchQueue.main)
//                        .first()
                }
                .map { Environment.ChartData(date: Date(), signal: $0.intValue) }
                .sink { completion in
                    // TODO: Update handling
                    switch completion {
                    case .finished: print("finished")
                    case .failure: print("failure")
                    }
                } receiveValue: { [unowned self] newSignalItem in
//                    print(newSignalItem.signal)
                    if newSignalItem.date.timeIntervalSince1970 - environment.scrolPosition.timeIntervalSince1970 < CGFloat(environment.visibleDomain + 5) || environment.chartData.isEmpty {
                        environment.scrolPosition = Date()
                    }
                    environment.chartData.append(newSignalItem)
                    
                    if environment.chartData.count > environment.capacity {
                        environment.chartData.removeFirst()
                    }
                    
                    let min = (environment.chartData.min { $0.signal < $1.signal }?.signal ?? -100)
                    let max  = (environment.chartData.max { $0.signal < $1.signal }?.signal ?? -40)
                    
                    environment.lowest = min - 5
                    environment.highest = max + 5
                }
                .store(in: &cancelable)
        }
    }
    
    // MARK: - Mock
    @MainActor
    class MockViewModel: ViewModel {
        static let shared = MockViewModel(peripheral: .preview)
        
        override func readSignal() {
            environment.chartData = Environment.ChartData.preview
        }
    }
}

extension SignalChartScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        struct ChartData: Identifiable {
            let date: Date
            let signal: Int
            var id: TimeInterval { date.timeIntervalSince1970 }
        }
        
        
        @Published fileprivate (set) var chartData: [ChartData] = []
        @Published var scrolPosition: Date = Date()
        
        let visibleDomain = 60
        let capacity = 180
        
        @Published fileprivate (set) var lowest: Int = -100
        @Published fileprivate (set) var highest: Int = -40
        
        init(chartData: [ChartData] = []) {
            self.chartData = chartData
            assert(capacity >= visibleDomain)
        }
    }
}
