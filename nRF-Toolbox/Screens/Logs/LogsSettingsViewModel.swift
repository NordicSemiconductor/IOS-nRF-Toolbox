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
    
    @Published var logs: [LogItemDomain]? = nil

    @Published var searchText: String = ""
    @Published var selectedLogLevel: LogLevel = .debug

    @Published var logsMeta: LogsMeta? = nil
    let readDataSource: LogsReadDataSource
    
    var isLoading: Bool = false
    @Published var page: Int = 0
    private let itemsPerPage: Int = 100
    
    private var cancellables = Set<AnyCancellable>()
    
    private var notificationTask: Task<Void, Never>? = nil


    init(container: ModelContainer) {
        self.readDataSource = LogsReadDataSource(modelContainer: container)
        observeFilterChange()
        fetchLogsCount()
    }
    
    func onAppear() {
        subscribeToNotifications()
    }
    
    func onDisappear() {
        notificationTask?.cancel()
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
            .sink { searchText, logLevel in
                self.reload()
            }
            .store(in: &cancellables)
    }

    func subscribeToNotifications() {
        notificationTask?.cancel()
        notificationTask = Task.detached {
            for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                
                let limit = await self.page * self.itemsPerPage
                let records = try? await self.readDataSource.fetch(searchText: self.searchText, logLevel: self.selectedLogLevel, limit: limit)
                
                await MainActor.run {
                    guard let records else { return }
                    self.logs = records
                }
                
                self.fetchLogsCount()
            }
        }
    }
    
    func reload() {
        guard !isLoading else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let limit = await self.page * self.itemsPerPage
            let records = try? await self.readDataSource.fetch(searchText: self.searchText, logLevel: self.selectedLogLevel, limit: limit)
        
            await MainActor.run {
                self.logs = records
                self.isLoading = false
                self.page += 1
            }
        }
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let records = try? await self.readDataSource.fetch(searchText: self.searchText, logLevel: self.selectedLogLevel, page: self.page, amountPerPage: self.itemsPerPage)
        
            await MainActor.run {
                self.logs?.append(contentsOf: records ?? [])
                self.isLoading = false
                self.page += 1
            }
        }
    }
}
