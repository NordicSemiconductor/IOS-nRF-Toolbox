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
    @Published var filteredLogs: [LogItemDomain]? = nil
    
    let writeDataSource: LogsWriteDataSource
    let readDataSource: LogsReadDataSource
    
    var isLoading: Bool = false
    @Published var page: Int = 0
    private let itemsPerPage: Int = 100
    
    private var cancellables = Set<AnyCancellable>()
    
    private var notificationTask: Task<Void, Never>? = nil

    init(container: ModelContainer) {
        self.writeDataSource = LogsWriteDataSource(modelContainer: container)
        self.readDataSource = LogsReadDataSource(modelContainer: container)
        observeLogs()
        observeFilterChange()
        subscribeToNotifications()
    }
    
    deinit {
        notificationTask?.cancel()
        notificationTask = nil
    }
    
    func observeFilterChange() {
        Publishers
            .CombineLatest($searchText, $selectedLogLevel)
            .sink { [weak self] searchText, logLevel in
                if self?.filteredLogs != nil {
                    self?.updateFilters(searchText: searchText, level: logLevel)
                }
            }
            .store(in: &cancellables)
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
            for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                
                let limit = await self.page * self.itemsPerPage
                let records = try? await self.readDataSource.fetch(limit: limit)
                
                await MainActor.run {
                    guard let records else { return }
                    self.logs = records
                    self.updateFilters(searchText: self.searchText, level: self.selectedLogLevel)
                }
            }
        }
    }
    
    func insertRecord(_ item: LogItemDomain) {
        Task.detached(priority: .userInitiated) {
            try await self.writeDataSource.insert(item)
        }
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let records = try? await self.readDataSource.fetch(page: self.page, amountPerPage: self.itemsPerPage)
        
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
            try await self.writeDataSource.deleteAll()
        }
    }
}
