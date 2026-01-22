//
//  AppViewModel.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 22/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import iOS_Common_Libraries
import Foundation
import Combine

class AppViewModel : ObservableObject {
    
    @Published var logsSettings = LogsSettings()
    
    let writeDataSource: LogsWriteDataSource
    private let container: SwiftDataContextManager = SwiftDataContextManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.writeDataSource = LogsWriteDataSource(modelContainer: container.container!)
        observeLogs()
    }
    
    func observeLogs() {
        NordicLog.lastLog
            .filter { _ in self.logsSettings.isEnabled == true }
            .compactMap { $0 }
            .map { log in LogItemDomain(value: log.message, level: log.level.rawValue, timestamp: log.timestamp) }
            .sink(receiveValue: { log in self.insertRecord(log) } )
            .store(in: &cancellables)
    }
    
    func insertRecord(_ item: LogItemDomain) {
        Task.detached(priority: .userInitiated) {
            try await self.writeDataSource.insert(item)
        }
    }
    
    func clearLogs() {
        Task.detached(priority: .userInitiated) {
            try await self.writeDataSource.deleteAll()
        }
    }
}
