//
//  LogsWriteDataSource.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation
import iOS_Common_Libraries

@ModelActor
actor LogsWriteDataSource {
    
    private let log = NordicLog(category: "LogsWriteDataSource", subsystem: "com.nordicsemi.nrf-toolbox")
    
    @discardableResult
    func insert(_ item: LogItemDomain) throws -> PersistentIdentifier {
        let model = LogDb(from: item)
        modelContext.insert(model)
        try modelContext.save()
        return model.persistentModelID
    }
    
    func deleteAll() throws {
        try modelContext.delete(model: LogDb.self)
        try modelContext.save()
    }
}
