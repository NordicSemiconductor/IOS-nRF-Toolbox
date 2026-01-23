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
    
    @Published var logs: [LogItemDomain] = []

    @Published var searchText: String = ""
    @Published var selectedLogLevel: LogLevel = .debug
    @Published var filteredLogs: [LogItemDomain]? = nil

    @Published var logsMeta: LogsMeta? = nil
    let readDataSource: LogsReadDataSource
    
    var isLoading: Bool = false
    @Published var page: Int = 0
    private let itemsPerPage: Int = 100
    
    private var cancellables = Set<AnyCancellable>()
    
    private var notificationTask: Task<Void, Never>? = nil
    private var countTask: Task<(), any Error>? = nil

    init(container: ModelContainer) {
        self.readDataSource = LogsReadDataSource(modelContainer: container)
        observeFilterChange()
        subscribeToNotifications()
        fetchLogsCount()
    }
    
    deinit {
        print("AAATESTAAA - deinit")
        countTask?.cancel()
        notificationTask?.cancel()
        countTask = nil
        notificationTask = nil
    }
    
    private nonisolated func fetchLogsCount() {
        Task.detached {
            let count = try? await self.readDataSource.fetchCount()
            let meta = count != nil ? LogsMeta(size: Double(count!)) : nil
            
            await MainActor.run {
                self.logsMeta = meta
            }
        }
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
                (searchText.isEmpty ? true : log.value.localizedStandardContains(searchText)) && log.level <= selectedLogLevel.rawValue
            }

            await MainActor.run {
                self.filteredLogs = result
            }
        }
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
                
                self.fetchLogsCount()
            }
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
}
