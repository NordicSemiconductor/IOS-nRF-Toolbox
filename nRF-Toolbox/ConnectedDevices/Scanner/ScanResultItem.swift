//
//  ScanResultItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct ScanResultItem: View {
    let name: String?
    let rssi: Int
    
    var body: some View {
        VStack {
            HStack {
                RSSIView(rssi: BluetoothRSSI(rawValue: rssi))
                Text(name ?? "n/a")
                    .foregroundColor(name == nil ? .secondary : .primary)
            }
        }
    }
}

struct ScanResultItem_Previews: PreviewProvider {
    static var previews: some View {
        ScanResultItem(name: "Scanned Device", rssi: -80)
    }
}
