//
//  ReadableError.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 11/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct ReadableError: LocalizedError {
    let title: String
    let message: String?
    
    init(title: String, message: String?) {
        self.title = title
        self.message = message
    }
    
    init(error: Error) {
        title = "Error"
        message = error.localizedDescription
    }
    
    var localizedDescription: String {
        message ?? title
    }
    
    var failureReason: String? {
        message ?? title
    }
}
