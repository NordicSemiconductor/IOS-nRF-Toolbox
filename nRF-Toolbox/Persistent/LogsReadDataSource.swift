//
//  LogsReadDataSource.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 21/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation
import iOS_Common_Libraries

@ModelActor
actor LogsReadDataSource {
    
    private let log = NordicLog(category: "LogsReadDataSource", subsystem: "com.nordicsemi.nrf-toolbox")
    
    func fetchCount() throws -> Int {
        return try modelContext.fetchCount(FetchDescriptor<LogDb>())
    }
    
    func fetch(searchText: String, logLevel: LogLevel) throws -> [LogItemDomain] {
        try modelContext
            .fetch(getFetchDescriptor(searchText: searchText, logLevel: logLevel))
            .map { LogItemDomain(from: $0) }
    }
    
    func fetch(searchText: String, logLevel: LogLevel, limit: Int) throws -> [LogItemDomain] {
        var descriptor = getFetchDescriptor(searchText: searchText, logLevel: logLevel)
        descriptor.fetchLimit = limit
        
        return try modelContext
            .fetch(descriptor)
            .map { LogItemDomain(from: $0) }
    }
    
    func fetch(searchText: String, logLevel: LogLevel, page: Int, amountPerPage: Int) throws -> [LogItemDomain] {
        let alreadyFetched = page * amountPerPage
        
        var descriptor = getFetchDescriptor(searchText: searchText, logLevel: logLevel)
        descriptor.fetchLimit = amountPerPage
        descriptor.fetchOffset = alreadyFetched
        
        let fetched = try modelContext.fetch(descriptor)
        
        return fetched.map {
            LogItemDomain(from: $0)
        }
    }
    
    func getFetchDescriptor(searchText: String, logLevel: LogLevel) -> FetchDescriptor<LogDb> {
        return FetchDescriptor<LogDb>(
            predicate: #Predicate { log in
                (searchText.isEmpty ? true : log.value.localizedStandardContains(searchText)) && log.level <= logLevel.rawValue
            },
            sortBy: [
                SortDescriptor(\.timestamp, order: .reverse)
            ]
        )
    }
}
