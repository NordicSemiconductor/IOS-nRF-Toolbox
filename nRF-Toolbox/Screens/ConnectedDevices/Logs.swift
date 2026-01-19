//
//  Logs.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 02/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct Logs: Transferable {
    
    var values: [LogDb]
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { logs in
            return logs.values.map(\.displayString).joined(separator: "\n").data(using: .utf8)!
        }
    }
}

extension Logs {
    init() {
        values = []
    }
}
