//
//  LogsPreviewScreen.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 13/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import SwiftUI

struct LogsPreviewScreen: View {
    
    @Query(sort: \LogDb.timestamp) var logs: [LogDb]
    @State private var searchText: String = ""
    
    var filteredLogs: [LogDb] {
        if searchText.isEmpty {
            return logs
        } else {
            return logs.filter {
                $0.displayString.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredLogs) { log in
                Text(log.displayString)
                    .foregroundColor(log.levelColor)
            }
        }
        .searchable(text: $searchText)
    }
}

extension View {
    @ViewBuilder
    func applySearchBehaviorIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.searchToolbarBehavior(.minimize)
        } else {
            self
        }
    }
}
