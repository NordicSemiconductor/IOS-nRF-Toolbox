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

@MainActor
class LogsPreviewViewModel : ObservableObject {
    
    @Published var logsMeta: LogsMeta = LogsMeta()
    @Published var logs: [LogDb] = []
    @Published var filteredLogs: [LogDb] = []
    @Published var printableLogs: [String] = []
    
    func updateModel(searchText: String, logLevel: LogLevel) {
        filterLogs(logs: logs, searchText: searchText, logLevel: logLevel)
    }
    
    func updateModel(logs: [LogDb]) {
        self.logs = logs
        recalculateLogsMemorySize(of: logs)
    }
    
    func updatePrintableLogs() {
        printableLogs = logs.map { $0.displayString }
    }
    
    private func filterLogs(logs: [LogDb], searchText: String, logLevel: LogLevel) {
        let filteredBySearch = searchText.isEmpty
            ? logs
            : logs.filter { $0.displayString.localizedCaseInsensitiveContains(searchText) }
        
        filteredLogs = filteredBySearch.filter { $0.level == logLevel }
    }
    
    private func recalculateLogsMemorySize(of logs: [LogDb]) {
        Task {
            self.logsMeta = await self.memorySize(of: logs) ?? LogsMeta()
        }
    }
    
    // It's rather an estimation than exact evaluation.
    @concurrent
    private func memorySize(of logs: [LogDb]) async -> LogsMeta? {
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
