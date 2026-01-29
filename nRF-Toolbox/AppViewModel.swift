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

@Observable
final class AppViewModel {
    
    var logsSettings = LogsSettings()
    
    private var logCounter = 0
    let writeDataSource: LogsWriteDataSource
    private let container: SwiftDataContextManager = SwiftDataContextManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.writeDataSource = LogsWriteDataSource(modelContainer: container.container!)
        observeLogs()
        
        Task {
            let readDataSource = LogsReadDataSource(modelContainer: container.container!)
            logCounter = (try? await readDataSource.fetchCount()) ?? 0
        }
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
        logCounter += 1
        if logCounter > 100000 {
            clearLogs()
        }
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
