//
//  CaloriesResetState.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 30/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

enum CaloriesResetState: Equatable {
    case available
    case unavailable
    case inProgress
    case error(message: String)
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
