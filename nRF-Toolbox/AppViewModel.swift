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
import SwiftData

@Observable
final class AppViewModel {
    
    var logsSettings = LogsSettings()
    
    private let readDataSource: LogsReadDataSource
    private let writeDataSource: LogsWriteDataSource
    private var logCounter = 0
    private var clearTask: Task<(), Error>? = nil
 
    private let contextManager: SwiftDataContextManager = SwiftDataContextManager.shared
    private let log = NordicLog(category: "AppViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.readDataSource = LogsReadDataSource(modelContainer: contextManager.container!)
        self.writeDataSource = LogsWriteDataSource(modelContainer: contextManager.container!)
        observeLogs()

        NotificationCenter.default.publisher(for: ModelContext.didSave)
            .throttle(for: .seconds(1.0), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.refreshLogsCount()
            }
            .store(in: &cancellables)
    }
    
    private func refreshLogsCount() {
        Task.detached {
            self.logCounter = (try? await self.readDataSource.fetchCount()) ?? 0
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
        guard clearTask == nil else { return }
        clearTask = Task.detached(priority: .userInitiated) {
            do {
                self.log.debug("Deleting all logs.")
                let cleanDataSource = LogsWriteDataSource(modelContainer: self.contextManager.container!)
                try await cleanDataSource.deleteAll()
                self.log.info("Successfully deleted logs.")
            } catch let error {
                self.log.error("Deleting logs failed: \(error.localizedDescription)")
            }
            self.clearTask = nil
        }
    }
}
