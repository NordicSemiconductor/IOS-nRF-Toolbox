//
//  LogsPreviewScreen.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 13/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import SwiftUI
import iOS_Common_Libraries

struct LogsPreviewScreen: View {
    
    @Query(sort: \LogDb.timestamp) var logs: [LogDb]
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    
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
        VStack {
            ZStack(alignment: .leading) {
                
                BlinkingCursorView().hidden(!searchText.isEmpty)

                HStack(spacing: 0) {
                    TextField("Search logs", text: $searchText, prompt: Text("Search logs")).focused($isFocused).tint(.clear)
                    BlinkingCursorView().padding(.leading, 6).hidden()
                }
                
                HStack(spacing: 0) {
                    Text(searchText).lineLimit(1).hidden()
                    BlinkingCursorView().padding(.leading, 2).hidden(searchText.isEmpty)
                }
            }
            .padding()
            
            List {
                ForEach(filteredLogs) { log in
                    Text(log.displayString)
                        .foregroundColor(log.levelColor)
                }
            }
            .searchable(text: $searchText)
        }
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
