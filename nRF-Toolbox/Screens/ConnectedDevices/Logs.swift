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
    
    var values: [String]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .plainText) { transferable in
            let data = transferable.values.joined(separator: "\n").data(using: .utf8)!
            return data
        } importing: { data in
            if let string = String(data: data, encoding: .utf8) {
                let lines = string.components(separatedBy: .newlines)
                return Logs(values: lines)
            } else {
                return Logs()
            }
        }
    }
}

extension Logs {
    init() {
        values = []
    }
}
