//
//  QuickError.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol ReadableError: Error {
    var title: String { get }
    var readableMessage: String { get }
}

extension ReadableError {
    var title: String {
        return "Error"
    }
}

struct QuickError: ReadableError {
    let readableMessage: String
    
    init(message: String) {
        readableMessage = message
    }
}
