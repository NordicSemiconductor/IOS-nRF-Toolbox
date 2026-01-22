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
    
    @State private var scrollToTheTop = true
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
                
                Button {
                    scrollToTheTop = !scrollToTheTop
                } label: {
                    Image(systemName: scrollToTheTop ? "lock.slash" : "lock")
                }
                .padding()
            }
            
            LoadingListContainer(data: viewModel.filteredLogs) { logs in
                ScrollView {
                    LazyVStack {
                        ForEach(logs) { log in
                            LogItem(log: log)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .onAppear { logs.last == log ? viewModel.loadNextPage() : nil }
                            
                            if logs.last != log {
                                Separator()
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .ignoresSafeArea(.container, edges: .horizontal)
                .searchable(text: $viewModel.searchText)
                .scrollPosition($position, anchor: .top)
                .onChange(of: viewModel.filteredLogs) {
                    if scrollToTheTop {
                        position.scrollTo(x: 0)
                    }
                }
            }
        }
        .onAppear { viewModel.loadNextPage() }
    }
}

private struct LoadingListContainer<Data, Content: View>: View {
    
    let data: [Data]?
    @ViewBuilder let content: ([Data]) -> Content
    
    var body: some View {
        if let data = data {
            if data.isEmpty {
                Text("No records")
                    .foregroundColor(Color(.systemGray2))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content(data)
            }
        } else {
            ProgressView()
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct Separator: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
            .background(Color(.systemGray5))
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
