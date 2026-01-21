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
    
    func fetch() throws -> [LogItemDomain] {
        try modelContext
            .fetch(getFetchDescriptor())
            .map { LogItemDomain(from: $0) }
    }
    
    func fetch(limit: Int) throws -> [LogItemDomain] {
        var descriptor = getFetchDescriptor()
        descriptor.fetchLimit = limit
        
        return try modelContext
            .fetch(descriptor)
            .map { LogItemDomain(from: $0) }
    }
    
    func fetch(page: Int, amountPerPage: Int) throws -> [LogItemDomain] {
        let alreadyFetched = page * amountPerPage
        
        var descriptor = getFetchDescriptor()
        descriptor.fetchLimit = amountPerPage
        descriptor.fetchOffset = alreadyFetched
        
        let fetched = try modelContext.fetch(descriptor)
        
        return fetched.map {
            LogItemDomain(from: $0)
        }
    }
    
    func getFetchDescriptor() -> FetchDescriptor<LogDb> {
        return FetchDescriptor<LogDb>(
            sortBy: [
                SortDescriptor(\.timestamp, order: .reverse)
            ]
        )
    }
}
