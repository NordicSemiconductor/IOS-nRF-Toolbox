//
//  BeautifulLogFormat.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 28/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

protocol BeautifulLogFormat {
    
    func getLogString() -> String
}

extension BeautifulLogFormat {
    
    func newDataLog() -> String {
        return "Received a new measurement.\n\n\(getLogString())"
    }
}
