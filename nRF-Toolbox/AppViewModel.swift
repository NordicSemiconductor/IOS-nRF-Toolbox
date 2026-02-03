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

@MainActor
@Observable
final class AppViewModel {
    
    var logsSettings = LogsSettings()
    
    private let readDataSource: LogsReadDataSource
    private let writeDataSource: LogsWriteDataSource
    private var logCounter = 0
    private var clearTask: Task<(), Error>? = nil
 
    private let startLoggingSignal = PassthroughSubject<Void, Never>()
    private let contextManager: SwiftDataContextManager = SwiftDataContextManager.shared
    private let log = NordicLog(category: "AppViewModel", subsystem: "com.nordicsemi.nrf-toolbox")
    private var cancellables = Set<AnyCancellable>()
    
    @ObservationIgnored
    private lazy var parentPublisher: CurrentValueSubject<AnyPublisher<LogItemDomain, Never>, Never> = {
        return CurrentValueSubject<AnyPublisher<LogItemDomain, Never>, Never>(createNewPublisher())
    }()
    
    init() {
        self.readDataSource = LogsReadDataSource(modelContainer: contextManager.container!)
        self.writeDataSource = LogsWriteDataSource(modelContainer: contextManager.container!)
       
        observeLogs()
        refreshLogsCount()
    }
    
    private func refreshLogsCount() {
        Task.detached { [weak self] in
            let result = (try? await self?.readDataSource.fetchCount()) ?? 0
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.logCounter = result
                self.log.debug("Log counter fetched: \(self.logCounter)")
                self.startLoggingSignal.send(())
            }
        }
    }
    
    func observeLogs() {
        parentPublisher
            .switchToLatest()
            .sink(receiveValue: { log in self.insertRecord(log) } )
            .store(in: &cancellables)
    }
    
    private func createNewPublisher() -> AnyPublisher<LogItemDomain, Never>{
        return NordicLog.lastLog
            .filter { _ in self.logsSettings.isEnabled == true }
            .compactMap { $0 }
            .map { log in LogItemDomain(value: log.message, level: log.level.rawValue, timestamp: log.timestamp) }
            .buffer(size: .max, prefetch: .keepFull, whenFull: .dropOldest)
            .combineLatest(startLoggingSignal)
            .map(\.0)
            .eraseToAnyPublisher()
    }
    
    func insertRecord(_ item: LogItemDomain) {
        if logCounter > 100000 {
            clearLogs()
        }
        Task.detached(priority: .userInitiated) {
            try await self.writeDataSource.insert(item)
        }
    }
    
    func clearLogs() {
        guard clearTask == nil else { return }
        parentPublisher.send(createNewPublisher())
        let cleanDataSource = LogsWriteDataSource(modelContainer: self.contextManager.container!)
        clearTask = Task.detached(priority: .userInitiated) {
            do {
                self.log.debug("Deleting all logs.")
                try await cleanDataSource.deleteAll()
                self.log.info("Successfully deleted logs.")
            } catch let error {
                self.log.error("Deleting logs failed: \(error.localizedDescription)")
            }
            await MainActor.run {
                self.refreshLogsCount()
                self.clearTask = nil
            }
        }
    }
}
