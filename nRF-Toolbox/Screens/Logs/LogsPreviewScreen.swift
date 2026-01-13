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
    
    var body: some View {
        List {
            ForEach(logs) { value in
                Text(value.value)
            }
        }
        .navigationTitle("Logs preview")
    }
}
