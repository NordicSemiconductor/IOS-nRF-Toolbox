//
//  BadgeView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import iOS_Bluetooth_Numbers_Database

// MARK: - BadgeView

extension BadgeView {
    
    // MARK: init
    
    init(service: Service) {
        self.init(image: service.systemImage ?? Image(systemName: ""),
                  name: service.name,
                  color: service.color ?? .secondary)
    }
}
