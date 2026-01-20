//
//  LogsSettingsViewModel.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 16/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import iOS_Common_Libraries
import SwiftData

@MainActor
class LogsSettingsViewModel : ObservableObject {
    
    private let log = NordicLog(category: "LogsSettingsScreen", subsystem: "com.nordicsemi.nrf-toolbox")
    
    @Published var logsSettings = LogsSettings()
    
    @Published var logs: [LogItemDomain] = []
    
    @Published var searchText: String = ""
    @Published var selectedLogLevel: LogLevel = .debug
    @Published var filteredLogs: [LogItemDomain] = []
    
    let store: LogsDataSource
    var isLoading: Bool = false
    @Published var page: Int = 0
    let itemsPerPage: Int = 100
    
    private var cancellables = Set<AnyCancellable>()
    
    private var notificationTask: Task<Void, Never>? = nil

    init(container: ModelContainer) {
        self.store = LogsDataSource(modelContainer: container)
        observeLogs()
        subscribeToNotifications()
    }
    
    deinit {
        notificationTask?.cancel()
        notificationTask = nil
    }
    
    func updateFilters(
        searchText: String,
        level: LogLevel
    ) {
        let sourceLogs = logs
        
        self.searchText = searchText
        self.selectedLogLevel = level
        
        let selectedLogLevel = level

        Task.detached(priority: .userInitiated) {
            let result = sourceLogs.filter { log in
                (searchText.isEmpty ? true : log.value.localizedStandardContains(searchText)) && log.level == selectedLogLevel.rawValue
            }

            await MainActor.run {
                self.filteredLogs = result
            }
        }
    }
    
    func observeLogs() {
        NordicLog.lastLog
            .filter { _ in self.logsSettings.isEnabled == true}
            .compactMap { $0 }
            .map { log in LogItemDomain(value: log.message, level: log.level.rawValue, timestamp: log.timestamp) }
            .sink(receiveValue: { log in self.insertRecord(log) } )
            .store(in: &cancellables)
    }
    
    func subscribeToNotifications() {
        notificationTask = Task.detached {
            for await notification in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                let context = ModelContext(self.store.modelContainer)
                let page = await self.page
                let itemsPerPage = self.itemsPerPage
                
                var descriptor = FetchDescriptor<LogDb>()
                descriptor.fetchLimit = page * itemsPerPage
                
                let records = try? context.fetch(descriptor).compactMap { LogItemDomain(from: $0) }
                await MainActor.run {
                    guard let records else { return }
                    self.logs = records
                }
            }
        }
    }
    
    func insertRecord(_ item: LogItemDomain) {
        Task.detached(priority: .userInitiated) {
            try await self.store.insert(item)
        }
    }
    
    func loadRecords() {
        guard !isLoading else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let records = try? await self.store.fetch(page: self.page, amountPerPage: self.itemsPerPage)
        
            await MainActor.run {
                self.logs.append(contentsOf: records ?? [])
                self.isLoading = false
                self.page += 1
                self.updateFilters(searchText: self.searchText, level: self.selectedLogLevel)
            }
        }
    }
    
    func clearLogs() {
        Task.detached(priority: .userInitiated) {
            try await self.store.deleteAll()
        }
    }
}
