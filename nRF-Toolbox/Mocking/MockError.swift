//
//  MockError.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 27/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

enum MockError: Error {
    case notifyIsNotSupported, readingIsNotSupported, writingIsNotSupported, notificationsNotEnabled, incorrectCommand
}
