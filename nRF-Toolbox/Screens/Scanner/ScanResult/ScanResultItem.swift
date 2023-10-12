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

struct ScanResultItem: View {
    let name: String?
    let rssi: Int
    let services: [Service]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                RSSIView(rssi: BluetoothRSSI(rawValue: rssi))
                Text(name ?? "n/a")
                    .foregroundColor(name == nil ? .secondary : .primary)
            }
            
            ServiceBadgeGroup(services: services)
        }
    }
}

#Preview {
    List {
        ScanResultItem(name: "Service", rssi: -60, services: [.glucose])
        ScanResultItem(name: "Service", rssi: -70, services: [.glucose, .weightScale])
        ScanResultItem(name: "Service", rssi: -70, services: [.weightScale])
        ScanResultItem(name: "Service", rssi: -70, services: [.weightScale, .adafruitAccelerometer])
        ScanResultItem(name: "Service", rssi: -190, services: [])
    }
}
