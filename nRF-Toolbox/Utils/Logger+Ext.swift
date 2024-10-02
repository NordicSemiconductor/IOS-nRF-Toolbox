//
//  Logger+Ext.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 21/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

extension NordicLog {
    init(category: String) {
        self.init(category: category, subsystem: "com.nordicsemi.nrf-toolbox")
    }
}
