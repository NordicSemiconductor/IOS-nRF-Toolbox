//
//  LogsPreviewViewModel.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 16/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import iOS_Common_Libraries

struct LogsPreview {
    let logsMeta: LogsMeta
    let filteredLogs: [LogDb]
    let printableLogs: [String]
}

extension LogsPreview {
    
    init() {
        self.init(logsMeta: LogsMeta(), filteredLogs: [], printableLogs: [])
    }
}

@MainActor
class LogsPreviewViewModel : ObservableObject {
    
    @Published var logs: [LogDb] = []
    @Published var searchText: String = ""
    @Published var selectedLogLevel: LogLevel = .debug
    
    @Published var logsPreview: LogsPreview = LogsPreview()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Publishers.CombineLatest3($logs, $searchText.debounce(for: .seconds(2), scheduler: DispatchQueue.global(qos: .utility)), $selectedLogLevel)
            .map { logs, searchText, logLevel -> LogsPreview in
                let filteredLogs = self.filterLogs(logs: logs, searchText: searchText, logLevel: logLevel)
                let metaData = self.memorySize(of: logs) ?? LogsMeta()
                let printableLogs = self.getPrintableLogs(logs: logs)
                
                return LogsPreview(logsMeta: metaData, filteredLogs: filteredLogs, printableLogs: printableLogs)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preview in
                self?.logsPreview = preview
            }
            .store(in: &cancellables)
    }
    
    func updateModel(searchText: String, logLevel: LogLevel) {
        self.searchText = searchText
        self.selectedLogLevel = logLevel
     
    }
    
    func updateModel(logs: [LogDb]) {
        self.logs = logs
    }
    
    func getPrintableLogs(logs: [LogDb]) -> [String] {
        return logs.map { $0.displayString }
    }
    
    private func filterLogs(logs: [LogDb], searchText: String, logLevel: LogLevel) -> [LogDb] {
        let filteredBySearch = searchText.isEmpty
            ? logs
            : logs.filter { $0.displayString.localizedCaseInsensitiveContains(searchText) }
        
        return filteredBySearch.filter { $0.level == logLevel }
    }
    
    // It's rather an estimation than exact evaluation.
    private func memorySize(of logs: [LogDb]) -> LogsMeta? {
        let totalSize = logs.reduce(0) { acc, item in
            let instanceSize = class_getInstanceSize(LogDb.self)
            let stringSize = item.value.utf8.count * MemoryLayout<UInt16>.size
            
            return acc + stringSize + instanceSize
        }
        
        return LogsMeta(size: Double(totalSize / (1024 * 1024)))
    }
    
    private func getSwiftDataStoreSize() -> LogsMeta? {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("default.store") else {
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[FileAttributeKey.size] as? UInt64 {
                let megabytes = Double(fileSize) / (1024 * 1024)
                return LogsMeta(size: megabytes)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return nil
    }
}
