//
//  Logger+Ext.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 21/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

extension L {
    init(category: String) {
        self.init(subsystem: "com.nordicsemi.nrf-toolbox", category: category)
    }
    
    func construct() {
        d("life-cycle-created")
    }
    
    func descruct() {
        w("life-cycle-destroyed")
    }
}
