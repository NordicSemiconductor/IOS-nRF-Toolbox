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
    
    @Binding private var searchText: String
    @Binding private var selectedLogLevel: LogLevel
    @FocusState private var isFocused: Bool
    
    @Query(sort: \LogDb.timestamp) var logs: [LogDb]
    
    init(searchText: Binding<String>, selectedLogLevel: Binding<LogLevel>) {
        self._searchText = searchText
        self._selectedLogLevel = selectedLogLevel
        
        let searchText = searchText.wrappedValue
        let selectedLogLevel = selectedLogLevel.wrappedValue
        
        if searchText.isEmpty {
            let predicate = #Predicate<LogDb> { log in
                log.level == selectedLogLevel.rawValue
            }
            _logs = Query(filter: predicate, sort: \LogDb.timestamp, order: .reverse)
        } else {
            let predicate = #Predicate<LogDb> { log in
                (searchText.isEmpty ? true : log.value.localizedStandardContains(searchText)) && log.level == selectedLogLevel.rawValue
            }
            _logs = Query(filter: predicate, sort: \LogDb.timestamp, order: .reverse)
        }
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
                ForEach(logs) { log in
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
                
                LogLevelItem(level: log.logLevel)
            }
            
            Text(log.value)
                .foregroundColor(log.logLevel.color)
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
