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
            
            servicesView
        }
    }
    
    @ViewBuilder
    var servicesView: some View {
        HStack {
            ForEach(services.filter({ $0.isSupported })) {
                ServiceBadge(image: $0.systemImage, name: $0.name, color: $0.color ?? .primary)
            }
            
            otherServiceBadge(count: services.reduce(0, { $0 + ($1.isSupported ? 0 : 1)  }))
        }
    }
    
    @ViewBuilder
    func otherServiceBadge(count: Int) -> some View {
        if count > 0 {
            ServiceBadge(name: otherServiceString(count: count))
        } else {
            EmptyView()
        }
    }
    
    private func otherServiceString(count: Int) -> String {
        let prefixSymbol = count == services.count ? "" : " +"
        
        let formatString : String = NSLocalizedString("service_count", comment: "")
        let resultString : String = String.localizedStringWithFormat(formatString, count)
        return prefixSymbol + resultString
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
