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
    
    @EnvironmentObject var viewModel: LogsSettingsViewModel
    
    @FocusState private var isFocused: Bool
    
    @State private var scrollToTheTop = false
    @State private var position: ScrollPosition = .init(idType: LogItemDomain.ID.self)
    
    var body: some View {
        VStack {
            HStack {
                ZStack(alignment: .leading) {
                    
                    BlinkingCursorView().hidden(!viewModel.searchText.isEmpty)

                    HStack(spacing: 0) {
                        TextField("Search logs", text: $viewModel.searchText, prompt: Text("Search logs")).focused($isFocused).tint(.clear)
                        BlinkingCursorView().padding(.leading, 6).hidden()
                    }
                    
                    HStack(spacing: 0) {
                        Text(viewModel.searchText).lineLimit(1).hidden()
                        BlinkingCursorView().padding(.leading, 2).hidden(viewModel.searchText.isEmpty)
                    }
                }
                .padding()
                
                Picker("Color", selection: $viewModel.selectedLogLevel, content: {
                    ForEach(LogLevel.allCases) { log in
                        LogLevelItem(level: log).tag(log)
                    }
                }, currentValueLabel: {
                    LogLevelItem(level: viewModel.selectedLogLevel)
                })
            }
            
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.filteredLogs) { log in
                        LogItem(log: log)
                            .padding()
                            .onAppear { viewModel.filteredLogs.last == log ? viewModel.loadNextPage() : nil }
                    }
                }
                .scrollTargetLayout()
            }
            .listStyle(.plain)
            .ignoresSafeArea(.container, edges: .horizontal)
            .searchable(text: $viewModel.searchText)
            .scrollPosition($position, anchor: .bottom)
        }
        .onAppear { viewModel.loadNextPage() }
    }
}

private struct LogItem: View {
    
    let log: LogItemDomain
    
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

private struct LogLevelItem: View {
    
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
