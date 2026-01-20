//
//  SwiftDataContextManager.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 06/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData

class SwiftDataContextManager{
    
    static let shared = SwiftDataContextManager()
    
    var container: ModelContainer?
    
    private init() {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: LogDb.self, configurations: configuration)
        } catch {
            debugPrint("Error initializing database container:", error)
        }
    }
}
