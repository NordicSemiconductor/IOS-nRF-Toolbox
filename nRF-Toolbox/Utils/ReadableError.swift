//
//  ReadableError.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 11/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - ReadableError

struct ReadableError: LocalizedError {
    
    // MARK: Properties
    
    let title: String
    let message: String?
    
    // MARK: init
    
    init(title: String, message: String?) {
        self.title = title
        self.message = message
    }
    
    init(_ error: Error) {
        title = "Error"
        message = error.localizedDescription
    }
    
    // MARK: Computed Properties
    
    var localizedDescription: String {
        message ?? title
    }
    
    var failureReason: String? {
        title
    }
    
    var errorDescription: String? {
        message
    }
}
