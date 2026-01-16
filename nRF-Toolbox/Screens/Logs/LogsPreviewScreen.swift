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
    @State private var selectedLogLevel: LogLevel = .debug
    @FocusState private var isFocused: Bool
    
    var filteredLogs: [LogDb] {
        let filteredBySearch = searchText.isEmpty
            ? logs
            : logs.filter { $0.displayString.localizedCaseInsensitiveContains(searchText) }
        
        return filteredBySearch.filter { $0.level == selectedLogLevel }
    }

    var body: some View {
        VStack {
            HStack {
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
                
                Picker("Color", selection: $selectedLogLevel, content: {
                    ForEach(LogLevel.allCases) { log in
                        LogLevelItem(level: log).tag(log)
                    }
                }, currentValueLabel: {
                    LogLevelItem(level: selectedLogLevel)
                })
            }
            
            List {
                ForEach(filteredLogs) { log in
                    LogItem(log: log)
                }
            }
            .listStyle(.plain)
            .ignoresSafeArea(.container, edges: .horizontal)
            .searchable(text: $searchText)
        }
    }
}

struct LogItem: View {
    
    let log: LogDb
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(log.displayDate)
                    .monospaced()
                    .font(.caption)
                
                Spacer()
                
                LogLevelItem(level: log.level)
            }
            
            Text(log.value)
                .foregroundColor(log.level.color)
                .monospaced()
        }
    }
}

struct LogLevelItem: View {
    
    let level: LogLevel
    
    var body: some View {
        Text(level.name)
            .foregroundColor(Color.white)
            .monospaced()
            .font(.caption)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(level.color)
            )
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
