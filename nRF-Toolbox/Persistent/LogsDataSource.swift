//
//  LogsDataSource.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation

@MainActor
class LogsDataSource {
    private let container: ModelContainer?
    private let context: ModelContext?
    
    init(container: ModelContainer?, context: ModelContext?) {
        self.container = container
        self.context = context
    }
    
    func insert(_ entity: LogDb) {
        self.container?.mainContext.insert(entity)
        try? self.container?.mainContext.save()
    }

    func delete(_ entity: LogDb) {
        self.container?.mainContext.delete(entity)
        try? self.container?.mainContext.save()
    }
    
    func fetchContacts() -> [LogDb] {
        let fetchDescriptor = FetchDescriptor<LogDb>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let contacts = try? self.container?.mainContext.fetch(fetchDescriptor)
        return contacts ?? []
    }
    
    func deleteAll() {
        try? context?.delete(model: LogDb.self)
    }
}
