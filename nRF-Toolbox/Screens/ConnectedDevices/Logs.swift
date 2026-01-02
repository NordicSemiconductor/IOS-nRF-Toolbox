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

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .plainText) { logs in
            let data = NordicLog.history.elements.joined(separator: "\n").data(using: .utf8)!
            return data
        } importing: { data in
            return Self()
        }
    }
}
