//
//  LogsSettingsViewModel.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 16/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import Combine
import Foundation
import iOS_Common_Libraries

@MainActor
class LogsSettingsViewModel : ObservableObject {
    
    @Published var logsSettings = LogsSettings()
    
    private let logsDataSource = LogsDataSource(
        container: SwiftDataContextManager.shared.container,
        context: SwiftDataContextManager.shared.context,
    )
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeLogs()
    }
    
    func observeLogs() {
        NordicLog.lastLog
            .filter { _ in self.logsSettings.isEnabled == true}
            .compactMap { $0 }
            .map { log in LogDb(value: log.message, level: log.level, timestamp: log.timestamp) }
            .sink(receiveValue: { log in self.logsDataSource.insert(log) } )
            .store(in: &cancellables)
        
        NordicLog.lastLog
            .filter { _ in self.logsSettings.isEnabled == true}
            .compactMap { $0 }
            .throttle(
                for: .seconds(10),
                scheduler: RunLoop.main,
                latest: true
            )
            .sink { record in
                self.logsDataSource.save()
            }
            .store(in: &cancellables)
    }
    
    func clearLogs() {
        self.logsDataSource.deleteAll()
    }
}
