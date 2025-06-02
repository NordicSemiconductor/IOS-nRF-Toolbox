//
//  ScanResultItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import iOS_Bluetooth_Numbers_Database

// MARK: - ScanResultItem

struct ScanResultItem: View {
    
    // MARK: Properties
    
    let name: String?
    let rssi: Int
    let services: Set<Service>
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name ?? "Unnamed Device")
                .foregroundColor(name == nil ? .secondary : .primary)
            
            ServiceBadgeGroup(services)
        }
    }
}
