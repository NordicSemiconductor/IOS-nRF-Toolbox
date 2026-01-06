//
//  SwiftDataContextManager.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation

@Model
final class LogDb {
    var value: String
    var timestamp: Date = Date()
    
    init(value: String) {
        self.value = value
    }
}

class SwiftDataContextManager{
    
    static let shared = SwiftDataContextManager()
    
    var container: ModelContainer?
    var context : ModelContext?
    
    private init() {
        do {
            container = try ModelContainer(for: LogDb.self)
            if let container {
                context = ModelContext(container)
            }
        } catch {
            debugPrint("Error initializing database container:", error)
        }
    }
}

@MainActor
class LogsDataSource {
    private let container: ModelContainer?
    private let context: ModelContext?
    
    init(container: ModelContainer?, context: ModelContext?) {
        self.container = container
        self.context = context
    }
}

extension LogsDataSource {
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
}
