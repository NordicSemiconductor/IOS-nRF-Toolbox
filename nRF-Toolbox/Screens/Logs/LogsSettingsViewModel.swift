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
@Observable
class LogsSettingsViewModel {
    
    private let log = NordicLog(category: "LogsSettingsScreen", subsystem: "com.nordicsemi.nrf-toolbox")

    var logs: [LogItemDomain]? = nil
    var logsMeta: LogsMeta? = nil
    var isLoading: Bool = false
    
    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    var searchText: String = "" {
        didSet {
            searchTextSubject.send(searchText)
        }
    }
    private let selectedLogLevelSubject = CurrentValueSubject<LogLevel, Never>(.debug)
    var selectedLogLevel: LogLevel = .debug {
        didSet {
            selectedLogLevelSubject.send(selectedLogLevel)
        }
    }
    
    private let readDataSource: LogsReadDataSource
    
    private var page: Int = 0
    private let itemsPerPage: Int = 100
    private var canLoadMore: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    private var activeLoadTask: Task<Void, Never>? = nil
    
    // MARK: init
    
    init(container: ModelContainer) {
        self.readDataSource = LogsReadDataSource(modelContainer: container)
        setupObservers()
        fetchLogsCount()
    }
    
    // MARK: deinit
    
    deinit {
        log.debug("\(type(of: self)).\(#function)")
    }
    
    private func setupObservers() {
        Publishers.CombineLatest(searchTextSubject, selectedLogLevelSubject)
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .removeDuplicates { prev, curr in
                prev.0 == curr.0 && prev.1 == curr.1
            }
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: ModelContext.didSave)
            .throttle(for: .seconds(1.0), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    func reload() {
        guard !isLoading else { return }
        activeLoadTask?.cancel()
        
        isLoading = true
        page = 0
        canLoadMore = true
        
        let currentSearch = searchText
        let currentLevel = selectedLogLevel
        let limit = itemsPerPage
        
        activeLoadTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let records = try? await self.readDataSource.fetch(
                searchText: currentSearch,
                logLevel: currentLevel,
                limit: limit
            )
            
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.logs = records
                self.isLoading = false
                self.fetchLogsCount()
            }
        }
    }

    func loadNextPage() {
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        
        let currentSearch = searchText
        let currentLevel = selectedLogLevel
        let nextPage = page + 1
        let amount = itemsPerPage
        
        activeLoadTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let newRecords = try? await self.readDataSource.fetch(
                searchText: currentSearch,
                logLevel: currentLevel,
                page: nextPage,
                amountPerPage: amount
            )
            
            await MainActor.run {
                guard !Task.isCancelled else { return }
                
                if let newRecords = newRecords, !newRecords.isEmpty {
                    if (self.logs == nil) {
                        self.logs = []
                    }
                    self.logs?.append(contentsOf: newRecords)
                    self.page += 1
                } else {
                    self.canLoadMore = false
                }
                self.isLoading = false
            }
        }
    }

    private nonisolated func fetchLogsCount() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            let count = try? await self.readDataSource.fetchCount()
            let meta = count != nil ? LogsMeta(size: Double(count!)) : nil
            
            await MainActor.run {
                self.logsMeta = meta
            }
        }
    }
}
