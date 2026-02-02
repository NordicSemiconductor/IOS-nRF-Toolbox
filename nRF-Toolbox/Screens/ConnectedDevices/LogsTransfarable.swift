//
//  LogsTransfarable.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 02/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import SwiftData

struct LogsTransfarable: Transferable {

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { logs in
            let container: ModelContainer = SwiftDataContextManager.shared.container!
            let dataSource = LogsReadDataSource(modelContainer: container)
            let result = try await dataSource.fetchAll()
            return result.map(\.displayString).joined(separator: "\n").data(using: .utf8)!
        }
    }
}
