//
//  QuickError.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol ReadableError: Error {
    var readableMessage: String { get }
}

struct QuickError: ReadableError {
    let readableMessage: String
    
    init(message: String) {
        readableMessage = message
    }
}
